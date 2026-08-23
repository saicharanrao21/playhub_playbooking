import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { BusinessStatus, BookingStatus } from '@prisma/client';

@Injectable()
export class AdminService {
  constructor(private prisma: PrismaService) {}

  async getDashboardStats() {
    const [totalUsers, totalVenues, activeBookings, pendingBusinesses] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.venue.count({ where: { status: 'ACTIVE' } }),
      this.prisma.booking.count({
        where: {
          status: { in: [BookingStatus.CONFIRMED, BookingStatus.PENDING] },
          startTime: { gte: new Date() }
        }
      }),
      this.prisma.business.findMany({
        where: { status: BusinessStatus.PENDING_ONBOARDING },
        include: { organization: true },
        take: 5,
      }),
    ]);

    return {
      totalUsers,
      totalVenues,
      activeBookings,
      pendingBusinesses,
    };
  }

  async approveBusiness(businessId: string) {
    const business = await this.prisma.business.findUnique({
      where: { id: businessId },
    });

    if (!business) {
      throw new NotFoundException('Business not found');
    }

    return this.prisma.business.update({
      where: { id: businessId },
      data: { status: BusinessStatus.ACTIVE },
    });
  }
}
