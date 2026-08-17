import { Injectable, NotFoundException, ForbiddenException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateVenueDto } from './dto/create-venue.dto';
import { UpdateVenueDto } from './dto/update-venue.dto';
import { OperatingHoursDto } from './dto/operating-hours.dto';

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

  async findAll(organizationId: string, businessId?: string) {
    return this.prisma.venue.findMany({
      where: {
        business: {
          organizationId,
          ...(businessId ? { id: businessId } : {}),
        },
      },
    });
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
        facilities: true,
        operatingHours: true,
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
