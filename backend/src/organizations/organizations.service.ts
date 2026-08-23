import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateOrganizationDto } from './dto/update-organization.dto';
import { BookingStatus } from '@prisma/client';

@Injectable()
export class OrganizationsService {
  constructor(private prisma: PrismaService) {}

  async findAll(filters: { skip?: number; take?: number }) {
    const [items, total] = await Promise.all([
      this.prisma.organization.findMany({
        skip: filters.skip,
        take: filters.take,
      }),
      this.prisma.organization.count(),
    ]);

    return { items, total };
  }

  async findOne(id: string) {
    const organization = await this.prisma.organization.findUnique({
      where: { id },
    });
    if (!organization) {
      throw new NotFoundException('Organization not found');
    }
    return organization;
  }

  async update(id: string, dto: UpdateOrganizationDto) {
    await this.findOne(id);
    return this.prisma.organization.update({
      where: { id },
      data: dto,
    });
  }

  async getDashboardStats(organizationId: string) {
    const now = new Date();
    const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const endOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

    const [venuesCount, facilitiesCount, todayBookings, upcomingBookings] = await Promise.all([
      this.prisma.venue.count({ where: { business: { organizationId }, status: 'ACTIVE' } }),
      this.prisma.facility.count({ where: { venue: { business: { organizationId } }, status: 'ACTIVE' } }),
      this.prisma.booking.count({
        where: {
          organizationId,
          startTime: { gte: startOfToday, lte: endOfToday },
          status: { in: [BookingStatus.CONFIRMED, BookingStatus.PENDING] }
        }
      }),
      this.prisma.booking.count({
        where: {
          organizationId,
          startTime: { gt: now },
          status: { in: [BookingStatus.CONFIRMED, BookingStatus.PENDING] }
        }
      }),
    ]);

    return {
      venuesCount,
      facilitiesCount,
      todayBookings,
      upcomingBookings,
    };
  }

  async getMembership(userId: string, organizationId: string) {
    return this.prisma.membership.findUnique({
      where: {
        userId_organizationId: {
          userId,
          organizationId,
        },
      },
      include: {
        roles: {
          include: {
            permissions: true,
          },
        },
      },
    });
  }
}
