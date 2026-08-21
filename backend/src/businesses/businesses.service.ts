import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateBusinessDto } from './dto/create-business.dto';
import { UpdateBusinessDto } from './dto/update-business.dto';

@Injectable()
export class BusinessesService {
  constructor(private prisma: PrismaService) {}

  async create(organizationId: string, dto: CreateBusinessDto) {
    return this.prisma.business.create({
      data: {
        ...dto,
        organizationId,
      },
    });
  }

  async findAll(organizationId: string, filters: { skip?: number; take?: number }) {
    const [items, total] = await Promise.all([
      this.prisma.business.findMany({
        where: { organizationId },
        skip: filters.skip,
        take: filters.take,
      }),
      this.prisma.business.count({
        where: { organizationId },
      }),
    ]);

    return { items, total };
  }

  async findOne(organizationId: string, id: string) {
    const business = await this.prisma.business.findFirst({
      where: { id, organizationId },
    });

    if (!business) {
      throw new NotFoundException('Business not found');
    }

    return business;
  }

  async update(organizationId: string, id: string, dto: UpdateBusinessDto) {
    // Ensure business belongs to organization
    await this.findOne(organizationId, id);

    return this.prisma.business.update({
      where: { id },
      data: dto,
    });
  }
}
