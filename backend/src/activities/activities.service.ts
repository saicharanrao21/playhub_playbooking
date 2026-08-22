import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateActivityDto } from './dto/create-activity.dto';
import { UpdateActivityDto } from './dto/update-activity.dto';

@Injectable()
export class ActivitiesService {
  constructor(private prisma: PrismaService) {}

  async create(dto: CreateActivityDto) {
    const existing = await this.prisma.activity.findUnique({
      where: {
        categoryId_slug: {
          categoryId: dto.categoryId,
          slug: dto.slug,
        },
      },
    });

    if (existing) {
      throw new ConflictException('Activity with this slug already exists for this category');
    }

    return this.prisma.activity.create({
      data: dto,
    });
  }

  async findAll(categoryId?: string) {
    return this.prisma.activity.findMany({
      where: {
        isActive: true,
        ...(categoryId ? { categoryId } : {}),
      },
      orderBy: { name: 'asc' },
    });
  }

  async findOne(id: string) {
    const activity = await this.prisma.activity.findUnique({
      where: { id },
      include: { category: true },
    });

    if (!activity) {
      throw new NotFoundException('Activity not found');
    }

    return activity;
  }

  async update(id: string, dto: UpdateActivityDto) {
    await this.findOne(id);
    return this.prisma.activity.update({
      where: { id },
      data: dto,
    });
  }
}
