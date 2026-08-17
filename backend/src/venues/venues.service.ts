import { Injectable, NotFoundException, ForbiddenException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateVenueDto } from './dto/create-venue.dto';

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

  async findAll(organizationId: string, businessId: string) {
    return this.prisma.venue.findMany({
      where: {
        business: {
          id: businessId,
          organizationId,
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
}
