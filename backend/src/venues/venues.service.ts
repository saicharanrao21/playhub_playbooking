import { Injectable, NotFoundException, ForbiddenException, ConflictException, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateVenueDto } from './dto/create-venue.dto';
import { UpdateVenueDto } from './dto/update-venue.dto';
import { OperatingHoursDto } from './dto/operating-hours.dto';
import { VenueStatus, FacilityStatus } from '@prisma/client';
import { DiscoveryFiltersDto } from '../discovery/dto/discovery-filters.dto';
import { NearbyVenuesQueryDto, DiscoverySortBy } from '../discovery/dto/nearby-venues-query.dto';
import { GeocodingService } from '../common/services/geocoding.service';
import { CacheService } from '../redis/cache.service';

@Injectable()
export class VenuesService {
  private readonly logger = new Logger(VenuesService.name);

  constructor(
    private prisma: PrismaService,
    private geocodingService: GeocodingService,
    private cacheService: CacheService,
  ) {}

  async create(organizationId: string, businessId: string, dto: CreateVenueDto) {
    // 1. Verify business ownership by organization
    const business = await this.prisma.business.findFirst({
      where: { id: businessId, organizationId },
    });

    if (!business) {
      throw new ForbiddenException('Unauthorized business context');
    }

    // 2. Check for duplicate slug within business
    const existing = await this.prisma.venue.findUnique({
      where: {
        businessId_slug: {
          businessId,
          slug: dto.slug,
        },
      },
    });

    if (existing) {
      throw new ConflictException('Venue with this slug already exists for this business');
    }

    // Auto-geocode if lat/lng are not explicitly provided
    let lat = dto.latitude;
    let lng = dto.longitude;
    if (lat === undefined || lng === undefined) {
      const geo = await this.geocodingService.geocodeAddress(dto.address, dto.city);
      lat = geo.latitude;
      lng = geo.longitude;
    }

    const created = await this.prisma.venue.create({
      data: {
        ...dto,
        latitude: lat,
        longitude: lng,
        businessId,
      },
    });

    this.cacheService.delPattern('venues:*').catch(() => {});
    return created;
  }

  async discover(filters: DiscoveryFiltersDto) {
    const where = {
      status: VenueStatus.ACTIVE,
      ...(filters.cityId ? { cityId: filters.cityId } : {}),
      ...(filters.query
        ? {
            OR: [
              { name: { contains: filters.query, mode: 'insensitive' as const } },
              { description: { contains: filters.query, mode: 'insensitive' as const } },
            ],
          }
        : {}),
      ...(filters.categoryId || filters.activityId
        ? {
            facilities: {
              some: {
                status: FacilityStatus.ACTIVE,
                ...(filters.categoryId ? { categoryId: filters.categoryId } : {}),
                ...(filters.activityId ? { activityId: filters.activityId } : {}),
              },
            },
          }
        : {}),
    };

    const [items, total] = await Promise.all([
      this.prisma.venue.findMany({
        where,
        include: {
          facilities: {
            where: { status: FacilityStatus.ACTIVE },
            include: { category: true, activity: true, media: true },
          },
          cityRel: true,
          media: true,
        },
        skip: filters.skip,
        take: filters.limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.venue.count({ where }),
    ]);

    return { items, total };
  }

  /**
   * High-performance radius search using bounding-box index filtering + exact Haversine calculation with Redis caching.
   */
  async findNearby(query: NearbyVenuesQueryDto) {
    const userLat = query.latitude ?? 17.4401;
    const userLng = query.longitude ?? 78.3489;
    const radiusKm = query.radius ?? 10.0;
    const cacheKey = `venues:nearby:${userLat.toFixed(3)}_${userLng.toFixed(3)}:${radiusKm}:${query.query || 'all'}:${query.cityId || 'all'}:${query.categoryId || 'all'}:${query.sortBy || 'dist'}:${query.skip || 0}:${query.limit || 20}`;

    return this.cacheService.getOrSet(
      cacheKey,
      async () => {
        // 1. Calculate Bounding Box for PostgreSQL Index Usage
        const box = this.geocodingService.getBoundingBox(userLat, userLng, radiusKm);

        const where: any = {
          status: VenueStatus.ACTIVE,
          latitude: { gte: box.minLat, lte: box.maxLat },
          longitude: { gte: box.minLng, lte: box.maxLng },
          ...(query.cityId ? { cityId: query.cityId } : {}),
          ...(query.query
            ? {
                OR: [
                  { name: { contains: query.query, mode: 'insensitive' as const } },
                  { description: { contains: query.query, mode: 'insensitive' as const } },
                  { address: { contains: query.query, mode: 'insensitive' as const } },
                  { city: { contains: query.query, mode: 'insensitive' as const } },
                ],
              }
            : {}),
          ...(query.categoryId || query.activityId
            ? {
                facilities: {
                  some: {
                    status: FacilityStatus.ACTIVE,
                    ...(query.categoryId ? { categoryId: query.categoryId } : {}),
                    ...(query.activityId ? { activityId: query.activityId } : {}),
                  },
                },
              }
            : {}),
        };

        // Fetch candidate venues matching bounding box index
        const candidates = await this.prisma.venue.findMany({
          where,
          include: {
            facilities: {
              where: { status: FacilityStatus.ACTIVE },
              include: { category: true, activity: true, media: true, pricingRules: { where: { isActive: true } } },
            },
            cityRel: true,
            media: true,
          },
        });

        // 2. Exact Haversine Distance Calculation & Radius Filtering
        const venuesWithDistance = candidates
          .map((v) => {
            const vLat = v.latitude!;
            const vLng = v.longitude!;
            const distMeters = this.geocodingService.calculateDistanceMeters(userLat, userLng, vLat, vLng);
            const distKm = distMeters / 1000.0;

            return {
              ...v,
              distanceMeters: distMeters,
              distanceKm: distKm,
              distanceFormatted: this.geocodingService.formatDistance(distMeters),
            };
          })
          .filter((v) => v.distanceKm <= radiusKm);

        // 3. Sorting
        if (query.sortBy === DiscoverySortBy.DISTANCE) {
          venuesWithDistance.sort((a, b) => a.distanceMeters - b.distanceMeters);
        } else if (query.sortBy === DiscoverySortBy.PRICE) {
          const getMinPrice = (v: typeof venuesWithDistance[0]) => {
            const prices = v.facilities.flatMap((f) =>
              f.pricingRules.map((pr) => Number(pr.basePrice)),
            );
            return prices.length > 0 ? Math.min(...prices) : 0;
          };
          venuesWithDistance.sort((a, b) => getMinPrice(a) - getMinPrice(b));
        } else if (query.sortBy === DiscoverySortBy.RATING || query.sortBy === DiscoverySortBy.POPULARITY) {
          venuesWithDistance.sort((a, b) => ((b as any).rating || 0) - ((a as any).rating || 0));
        }

        // 4. Pagination
        const skip = query.skip ?? 0;
        const limit = query.limit ?? 20;
        const paginatedItems = venuesWithDistance.slice(skip, skip + limit);

        return {
          userCoordinates: { latitude: userLat, longitude: userLng },
          radiusKm,
          total: venuesWithDistance.length,
          items: paginatedItems,
        };
      },
      300, // 5 min TTL
    );
  }

  async geocodeVenueAddress(organizationId: string, venueId: string) {
    const venue = await this.findOne(organizationId, venueId);
    const geo = await this.geocodingService.geocodeAddress(venue.address, venue.city);

    return this.prisma.venue.update({
      where: { id: venueId },
      data: {
        latitude: geo.latitude,
        longitude: geo.longitude,
      },
    });
  }

  async getVenuesMissingCoordinates() {
    return this.prisma.venue.findMany({
      where: {
        status: VenueStatus.ACTIVE,
        OR: [{ latitude: null }, { longitude: null }],
      },
      include: { business: { include: { organization: true } } },
    });
  }

  async batchGeocodeVenues() {
    const venues = await this.getVenuesMissingCoordinates();
    let updatedCount = 0;

    for (const v of venues) {
      const geo = await this.geocodingService.geocodeAddress(v.address, v.city);
      await this.prisma.venue.update({
        where: { id: v.id },
        data: { latitude: geo.latitude, longitude: geo.longitude },
      });
      updatedCount++;
    }

    return { total: venues.length, updatedCount };
  }

  async findAll(organizationId: string, filters: { businessId?: string; skip?: number; take?: number }) {
    const [items, total] = await Promise.all([
      this.prisma.venue.findMany({
        where: {
          business: {
            organizationId,
            ...(filters.businessId ? { id: filters.businessId } : {}),
          },
        },
        skip: filters.skip,
        take: filters.take,
      }),
      this.prisma.venue.count({
        where: {
          business: {
            organizationId,
            ...(filters.businessId ? { id: filters.businessId } : {}),
          },
        },
      }),
    ]);

    return { items, total };
  }

  async findOne(organizationId: string, id: string) {
    const venue = await this.prisma.venue.findFirst({
      where: {
        id,
        business: {
          organizationId,
        },
      },
      include: {
        facilities: {
          where: { status: FacilityStatus.ACTIVE },
          include: { category: true, activity: true },
        },
        operatingHours: true,
        cityRel: true,
      },
    });

    if (!venue) {
      throw new NotFoundException('Venue not found');
    }

    return venue;
  }

  async update(organizationId: string, id: string, dto: UpdateVenueDto) {
    await this.findOne(organizationId, id);

    let lat = dto.latitude;
    let lng = dto.longitude;
    if (lat === undefined && lng === undefined && (dto.address || dto.city)) {
      const existing = await this.prisma.venue.findUnique({ where: { id } });
      const geo = await this.geocodingService.geocodeAddress(
        dto.address || existing.address,
        dto.city || existing.city,
      );
      lat = geo.latitude;
      lng = geo.longitude;
    }

    const updated = await this.prisma.venue.update({
      where: { id },
      data: {
        ...dto,
        ...(lat !== undefined ? { latitude: lat } : {}),
        ...(lng !== undefined ? { longitude: lng } : {}),
      },
    });

    this.cacheService.delPattern('venues:*').catch(() => {});
    return updated;
  }

  async updateOperatingHours(organizationId: string, venueId: string, hours: OperatingHoursDto[]) {
    await this.findOne(organizationId, venueId);

    // Validate times
    for (const h of hours) {
      if (!h.isClosed && h.openingTime >= h.closingTime) {
        throw new ConflictException(`Invalid hours for ${h.dayOfWeek}: Opening time must be before closing time`);
      }
    }

    return this.prisma.$transaction(async (tx) => {
      // 1. Clear existing hours for this venue
      await tx.operatingHours.deleteMany({
        where: { venueId },
      });

      // 2. Create new hours
      return tx.operatingHours.createMany({
        data: hours.map(h => ({
          ...h,
          venueId,
        })),
      });
    });
  }
}
