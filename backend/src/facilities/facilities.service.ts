import { Injectable, NotFoundException, ForbiddenException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateFacilityDto } from './dto/create-facility.dto';
import { UpdateFacilityDto } from './dto/update-facility.dto';
import { CreateBlockDto } from './dto/create-block.dto';
import { CreatePricingRuleDto } from './dto/create-pricing-rule.dto';

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

  async findAll(organizationId: string, venueId: string, filters: { skip?: number; take?: number }) {
    const [items, total] = await Promise.all([
      this.prisma.facility.findMany({
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
          activity: true,
          media: true,
        },
        skip: filters.skip,
        take: filters.take,
      }),
      this.prisma.facility.count({
        where: {
          venueId,
          venue: {
            business: {
              organizationId,
            },
          },
        },
      }),
    ]);

    return { items, total };
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
        activity: true,
        availabilityBlocks: true,
        pricingRules: true,
        media: true,
      },
    });

    if (!facility) {
      throw new NotFoundException('Facility not found');
    }

    return facility;
  }

  async getPricingRules(organizationId: string, facilityId: string) {
    await this.findOne(organizationId, facilityId);
    return this.prisma.pricingRule.findMany({
      where: { facilityId },
      orderBy: { priority: 'desc' },
    });
  }

  async update(organizationId: string, id: string, dto: UpdateFacilityDto) {
    await this.findOne(organizationId, id);

    return this.prisma.facility.update({
      where: { id },
      data: dto,
    });
  }

  async createBlock(organizationId: string, facilityId: string, dto: CreateBlockDto) {
    await this.findOne(organizationId, facilityId);

    const start = new Date(dto.startTime);
    const end = new Date(dto.endTime);

    if (start >= end) {
      throw new ConflictException('Start time must be before end time');
    }

    return this.prisma.availabilityBlock.create({
      data: {
        ...dto,
        startTime: start,
        endTime: end,
        facilityId,
      },
    });
  }

  async deleteBlock(organizationId: string, facilityId: string, blockId: string) {
    await this.findOne(organizationId, facilityId);

    return this.prisma.availabilityBlock.delete({
      where: { id: blockId, facilityId },
    });
  }

  async createPricingRule(organizationId: string, facilityId: string, dto: CreatePricingRuleDto) {
    await this.findOne(organizationId, facilityId);

    return this.prisma.pricingRule.create({
      data: {
        ...dto,
        facilityId,
        effectiveFrom: dto.effectiveFrom ? new Date(dto.effectiveFrom) : null,
        effectiveTo: dto.effectiveTo ? new Date(dto.effectiveTo) : null,
      },
    });
  }

  async deletePricingRule(organizationId: string, facilityId: string, ruleId: string) {
    await this.findOne(organizationId, facilityId);

    return this.prisma.pricingRule.delete({
      where: { id: ruleId, facilityId },
    });
  }
}
