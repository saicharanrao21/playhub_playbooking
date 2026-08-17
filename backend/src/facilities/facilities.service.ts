import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateFacilityDto } from './dto/create-facility.dto';

@Injectable()
export class FacilitiesService {
  constructor(private prisma: PrismaService) {}

  async create(organizationId: string, venueId: string, dto: CreateFacilityDto) {
    // 1. Verify venue ownership by organization
    const venue = await this.prisma.venue.findFirst({
      where: {
        id: venueId,
        business: {
          organizationId,
        },
      },
    });

    if (!venue) {
      throw new ForbiddenException('Unauthorized venue context');
    }

    return this.prisma.facility.create({
      data: {
        ...dto,
        venueId,
      },
    });
  }

  async findAll(organizationId: string, venueId: string) {
    return this.prisma.facility.findMany({
      where: {
        venueId,
        venue: {
          business: {
            organizationId,
          },
        },
      },
      include: {
        category: true,
      },
    });
  }

  async findOne(organizationId: string, id: string) {
    const facility = await this.prisma.facility.findFirst({
      where: {
        id,
        venue: {
          business: {
            organizationId,
          },
        },
      },
      include: {
        category: true,
        availabilityBlocks: true,
        pricingRules: true,
      },
    });

    if (!facility) {
      throw new NotFoundException('Facility not found');
    }

    return facility;
  }
}
