import { Injectable, NotFoundException, ForbiddenException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateVenueDto } from './dto/create-venue.dto';
import { UpdateVenueDto } from './dto/update-venue.dto';
import { OperatingHoursDto } from './dto/operating-hours.dto';
import { VenueStatus, FacilityStatus } from '@prisma/client';
import { DiscoveryFiltersDto } from '../discovery/dto/discovery-filters.dto';

@Injectable()
export class VenuesService {
  constructor(private prisma: PrismaService) {}

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

    return this.prisma.venue.create({
      data: {
        ...dto,
        businessId,
      },
    });
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
            include: { category: true, activity: true },
          },
          cityRel: true,
        },
        skip: filters.skip,
        take: filters.limit,
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.venue.count({ where }),
    ]);

    return { items, total };
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

    return this.prisma.venue.update({
      where: { id },
      data: dto,
    });
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
