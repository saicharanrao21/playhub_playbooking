import { Injectable, Logger, Optional } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AnalyticsFilterDto, DatePreset } from './dto/analytics-filter.dto';
import { CacheService } from '../redis/cache.service';
import { MetricsService } from '../observability/metrics.service';

export interface DateRange {
  start: Date;
  end: Date;
  previousStart: Date;
  previousEnd: Date;
}

@Injectable()
export class AnalyticsService {
  private readonly logger = new Logger(AnalyticsService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly cacheService?: CacheService,
    @Optional() private readonly metricsService?: MetricsService,
  ) {}

  /**
   * Calculates current and previous comparison date ranges in UTC.
   */
  getDateRange(dto: AnalyticsFilterDto): DateRange {
    const end = dto.endDate ? new Date(dto.endDate) : new Date();
    let start = new Date(end);

    const preset = dto.preset || DatePreset.LAST_30_DAYS;

    if (dto.startDate && preset === DatePreset.CUSTOM) {
      start = new Date(dto.startDate);
    } else {
      switch (preset) {
        case DatePreset.TODAY:
          start.setHours(0, 0, 0, 0);
          break;
        case DatePreset.YESTERDAY:
          start.setDate(start.getDate() - 1);
          start.setHours(0, 0, 0, 0);
          end.setDate(end.getDate() - 1);
          end.setHours(23, 59, 59, 999);
          break;
        case DatePreset.LAST_7_DAYS:
          start.setDate(start.getDate() - 7);
          break;
        case DatePreset.THIS_MONTH:
          start.setDate(1);
          start.setHours(0, 0, 0, 0);
          break;
        case DatePreset.LAST_MONTH:
          start.setMonth(start.getMonth() - 1);
          start.setDate(1);
          start.setHours(0, 0, 0, 0);
          end.setDate(0); // Last day of previous month
          end.setHours(23, 59, 59, 999);
          break;
        case DatePreset.LAST_30_DAYS:
        default:
          start.setDate(start.getDate() - 30);
          break;
      }
    }

    const durationMs = end.getTime() - start.getTime();
    const previousEnd = new Date(start.getTime() - 1);
    const previousStart = new Date(previousEnd.getTime() - durationMs);

    return { start, end, previousStart, previousEnd };
  }

  /**
   * Partner Organization Analytics Dashboard.
   */
  async getPartnerDashboardAnalytics(organizationId: string, query: AnalyticsFilterDto) {
    const cacheKey = `analytics:partner:${organizationId}:${query.preset || '30d'}:${query.venueId || 'all'}`;

    if (this.cacheService) {
      const cached = await this.cacheService.get(cacheKey);
      if (cached) return cached;
    }

    const range = this.getDateRange(query);

    // Filter clause for bookings
    const whereBooking: any = {
      organizationId,
      createdAt: { gte: range.start, lte: range.end },
      ...(query.venueId ? { facility: { venueId: query.venueId } } : {}),
      ...(query.facilityId ? { facilityId: query.facilityId } : {}),
    };

    const prevWhereBooking: any = {
      organizationId,
      createdAt: { gte: range.previousStart, lte: range.previousEnd },
      ...(query.venueId ? { facility: { venueId: query.venueId } } : {}),
      ...(query.facilityId ? { facilityId: query.facilityId } : {}),
    };

    // Parallel Aggregations
    const [
      totalBookings,
      confirmedBookings,
      cancelledBookings,
      prevBookings,
      paymentsAgg,
      refundsAgg,
      venueBreakdown,
      uniqueCustomersCount,
    ] = await Promise.all([
      this.prisma.booking.count({ where: whereBooking }),
      this.prisma.booking.count({ where: { ...whereBooking, status: 'CONFIRMED' } }),
      this.prisma.booking.count({ where: { ...whereBooking, status: 'CANCELLED' } }),
      this.prisma.booking.count({ where: prevWhereBooking }),
      this.prisma.payment.aggregate({
        where: { organizationId, status: 'CAPTURED', createdAt: { gte: range.start, lte: range.end } },
        _sum: { amount: true },
      }),
      this.prisma.payment.aggregate({
        where: { organizationId, status: 'REFUNDED', createdAt: { gte: range.start, lte: range.end } },
        _sum: { amount: true },
      }),
      this.prisma.venue.findMany({
        where: { business: { organizationId }, status: 'ACTIVE' },
        select: { id: true, name: true },
      }),
      this.prisma.booking.groupBy({
        by: ['userId'],
        where: whereBooking,
      }),
    ]);

    const grossRevenue = Number(paymentsAgg._sum.amount) || 0;
    const totalRefunds = Number(refundsAgg._sum.amount) || 0;
    const netRevenue = Math.max(0, grossRevenue - totalRefunds);

    const cancellationRate = totalBookings > 0 ? Math.round((cancelledBookings / totalBookings) * 10000) / 100 : 0;
    const bookingGrowthPercent = prevBookings > 0 ? Math.round(((totalBookings - prevBookings) / prevBookings) * 10000) / 100 : 0;

    const result = {
      dateRange: {
        startDate: range.start.toISOString(),
        endDate: range.end.toISOString(),
      },
      revenue: {
        grossRevenue,
        totalRefunds,
        netRevenue,
        currency: 'INR',
      },
      bookings: {
        totalBookings,
        confirmedBookings,
        cancelledBookings,
        cancellationRate,
        bookingGrowthPercent,
      },
      customers: {
        uniqueCustomers: uniqueCustomersCount.length,
      },
      venuesCount: venueBreakdown.length,
    };

    if (this.cacheService) {
      this.cacheService.set(cacheKey, result, 300).catch(() => {});
    }

    return result;
  }

  /**
   * Generates a 7x24 Peak-Time Booking Density Heatmap.
   */
  async getPeakTimesHeatmap(organizationId: string, query: AnalyticsFilterDto) {
    const range = this.getDateRange(query);

    const bookings = await this.prisma.booking.findMany({
      where: {
        organizationId,
        status: { in: ['CONFIRMED', 'CHECKED_IN', 'COMPLETED'] },
        startTime: { gte: range.start, lte: range.end },
        ...(query.venueId ? { facility: { venueId: query.venueId } } : {}),
      },
      select: { startTime: true, totalPrice: true },
    });

    // Initialize 7 Days x 24 Hours Grid
    // Day 0 = Sunday, 1 = Monday ... 6 = Saturday
    const grid: Array<Array<{ day: number; hour: number; bookingCount: number; totalRevenue: number }>> = [];

    for (let day = 0; day < 7; day++) {
      const hoursRow = [];
      for (let hour = 0; hour < 24; hour++) {
        hoursRow.push({ day, hour, bookingCount: 0, totalRevenue: 0 });
      }
      grid.push(hoursRow);
    }

    for (const b of bookings) {
      const dt = new Date(b.startTime);
      const day = dt.getDay();
      const hour = dt.getHours();

      grid[day][hour].bookingCount += 1;
      grid[day][hour].totalRevenue += Number(b.totalPrice || 0);
    }

    return {
      dateRange: { startDate: range.start.toISOString(), endDate: range.end.toISOString() },
      totalBookingsAnalyzed: bookings.length,
      heatmapGrid: grid,
    };
  }

  /**
   * Platform Admin Overview Analytics.
   */
  async getAdminPlatformAnalytics(query: AnalyticsFilterDto) {
    const range = this.getDateRange(query);

    const [
      totalOrganizations,
      totalVenues,
      totalCustomers,
      totalBookings,
      grossPaymentsAgg,
    ] = await Promise.all([
      this.prisma.organization.count({ where: { status: 'ACTIVE' } }),
      this.prisma.venue.count({ where: { status: 'ACTIVE' } }),
      this.prisma.user.count(),
      this.prisma.booking.count({ where: { createdAt: { gte: range.start, lte: range.end } } }),
      this.prisma.payment.aggregate({
        where: { status: 'CAPTURED', createdAt: { gte: range.start, lte: range.end } },
        _sum: { amount: true },
      }),
    ]);

    const grossVolume = Number(grossPaymentsAgg._sum.amount) || 0;
    const estimatedPlatformCommission = Math.round(grossVolume * 0.10); // 10% average platform commission

    return {
      dateRange: { startDate: range.start.toISOString(), endDate: range.end.toISOString() },
      overview: {
        totalOrganizations,
        totalVenues,
        totalCustomers,
        totalBookings,
        grossPaymentVolume: grossVolume,
        estimatedPlatformCommission,
        currency: 'INR',
      },
    };
  }
}
