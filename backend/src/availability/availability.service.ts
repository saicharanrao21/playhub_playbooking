import { Injectable, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { DateTime } from 'luxon';
import { TimeInterval } from '../common/utils/time-interval.util';
import { DayOfWeek, BookingStatus } from '@prisma/client';

@Injectable()
export class AvailabilityService {
  constructor(private prisma: PrismaService) {}

  async getAvailability(
    organizationId: string,
    facilityId: string,
    dateStr: string, // YYYY-MM-DD
    durationMinutes: number = 60,
    tx?: any, // Optional transaction client
  ) {
    const prisma = tx || this.prisma;

    // 1. Ownership & Existence Validation
    const facility = await prisma.facility.findFirst({
      where: {
        id: facilityId,
        venue: {
          business: {
            organizationId,
          },
        },
      },
      include: {
        venue: {
          include: {
            operatingHours: true,
          },
        },
      },
    });

    if (!facility) {
      throw new NotFoundException('Facility not found or unauthorized');
    }

    const venue = facility.venue;
    const timezone = venue.timezone;

    // 2. Parse Date in Venue Timezone
    const date = DateTime.fromISO(dateStr, { zone: timezone }).startOf('day');
    if (!date.isValid) {
      throw new BadRequestException('Invalid date format');
    }

    const dayOfWeek = date.weekdayLong.toUpperCase() as DayOfWeek;

    // 3. Get Operating Hours for the day
    const hours = venue.operatingHours.filter(h => h.dayOfWeek === dayOfWeek && !h.isClosed);
    if (hours.length === 0) {
      return {
        facilityId,
        date: dateStr,
        timezone,
        availableIntervals: [],
        slots: [],
      };
    }

    // Convert operating hours to absolute intervals in venue timezone
    let availableIntervals = hours.map(h => {
      const start = date.set({
        hour: parseInt(h.openingTime.split(':')[0]),
        minute: parseInt(h.openingTime.split(':')[1]),
      });
      const end = date.set({
        hour: parseInt(h.closingTime.split(':')[0]),
        minute: parseInt(h.closingTime.split(':')[1]),
      });
      return new TimeInterval(start, end);
    });

    // 4. Fetch and Subtract Availability Blocks & Bookings
    const startOfDay = date.toJSDate();
    const endOfDay = date.endOf('day').toJSDate();

    const [blocks, bookings] = await Promise.all([
      prisma.availabilityBlock.findMany({
        where: {
          facilityId,
          startTime: { lt: endOfDay },
          endTime: { gt: startOfDay },
        },
      }),
      prisma.booking.findMany({
        where: {
          facilityId,
          status: { in: [BookingStatus.PENDING, BookingStatus.CONFIRMED] },
          startTime: { lt: endOfDay },
          endTime: { gt: startOfDay },
        },
      }),
    ]);

    const subtractIntervals: TimeInterval[] = [
      ...blocks.map(b => new TimeInterval(
        DateTime.fromJSDate(b.startTime).setZone(timezone),
        DateTime.fromJSDate(b.endTime).setZone(timezone),
      )),
      ...bookings.map(b => new TimeInterval(
        DateTime.fromJSDate(b.startTime).setZone(timezone),
        DateTime.fromJSDate(b.endTime).setZone(timezone),
      )),
    ];

    // Subtract blocks and bookings from operating hours
    availableIntervals = TimeInterval.subtractMany(availableIntervals, subtractIntervals);

    // 5. Slot Generation
    const slots: TimeInterval[] = [];
    for (const interval of availableIntervals) {
      let currentStart = interval.start;
      while (currentStart.plus({ minutes: durationMinutes }) <= interval.end) {
        const slotEnd = currentStart.plus({ minutes: durationMinutes });
        slots.push(new TimeInterval(currentStart, slotEnd));
        currentStart = slotEnd;
      }
    }

    return {
      facilityId,
      date: dateStr,
      timezone,
      availableIntervals,
      slots,
    };
  }
}
