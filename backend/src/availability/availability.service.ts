import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { DateTime } from 'luxon';
import { TimeInterval } from '../common/utils/time-interval.util';
import { DayOfWeek, BookingStatus } from '@prisma/client';
import { PricingService } from './pricing.service';

@Injectable()
export class AvailabilityService {
  private readonly logger = new Logger(AvailabilityService.name);

  constructor(
    private prisma: PrismaService,
    private pricingService: PricingService,
  ) {}

  async getAvailability(
    organizationId: string,
    facilityId: string,
    dateStr: string, // YYYY-MM-DD
    durationMinutes?: number,
    tx?: any,
  ) {
    const prisma = tx || this.prisma;

    // 1. Fetch Facility, Venue, Operating Hours, and blocks
    const facility = await prisma.facility.findFirst({
      where: {
        id: facilityId,
        venue: { business: { organizationId } },
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
    const effectiveDuration = durationMinutes || facility.defaultSlotDuration;

    // 2. Parse Date
    const date = DateTime.fromISO(dateStr, { zone: timezone }).startOf('day');
    if (!date.isValid) throw new BadRequestException('Invalid date format');

    const dayOfWeek = date.weekdayLong.toUpperCase() as DayOfWeek;

    // 3. Operating Hours -> Base Intervals
    const hours = venue.operatingHours.filter(h => h.dayOfWeek === dayOfWeek && !h.isClosed);

    // Sort and merge just in case there are overlapping periods
    let availableIntervals = hours.map(h => {
      const start = date.set({
        hour: parseInt(h.openingTime.split(':')[0]),
        minute: parseInt(h.openingTime.split(':')[1]),
      });
      let end = date.set({
        hour: parseInt(h.closingTime.split(':')[0]),
        minute: parseInt(h.closingTime.split(':')[1]),
      });

      // Handle overnight operating hours (e.g. 22:00 -> 02:00)
      if (end <= start) {
        end = end.plus({ days: 1 });
      }

      return new TimeInterval(start, end);
    });

    if (availableIntervals.length === 0) {
      return { facilityId, date: dateStr, timezone, slots: [] };
    }

    availableIntervals = TimeInterval.merge(availableIntervals);

    // 4. Subtract Blocks (Fixed and Recurring) and Bookings
    const startOfQuery = date.toJSDate();
    const endOfQuery = date.plus({ days: 1 }).toJSDate();

    const [blocks, bookings] = await Promise.all([
      prisma.availabilityBlock.findMany({
        where: {
          facilityId,
          OR: [
            // Fixed blocks
            { isRecurring: false, startTime: { lt: endOfQuery }, endTime: { gt: startOfQuery } },
            // Recurring blocks for this day of week
            { isRecurring: true, dayOfWeek },
          ],
        },
      }),
      prisma.booking.findMany({
        where: {
          facilityId,
          status: { in: [BookingStatus.PENDING, BookingStatus.CONFIRMED] },
          startTime: { lt: endOfQuery },
          endTime: { gt: startOfQuery },
        },
      }),
    ]);

    const subtractIntervals: TimeInterval[] = [];

    // Recurring blocks
    for (const b of blocks.filter(x => x.isRecurring)) {
      const bStart = date.set({
        hour: b.startTime.getUTCHours(),
        minute: b.startTime.getUTCMinutes(),
      });
      let bEnd = date.set({
        hour: b.endTime.getUTCHours(),
        minute: b.endTime.getUTCMinutes(),
      });
      if (bEnd <= bStart) bEnd = bEnd.plus({ days: 1 });
      subtractIntervals.push(new TimeInterval(bStart, bEnd));
    }

    // Fixed blocks
    for (const b of blocks.filter(x => !x.isRecurring)) {
      subtractIntervals.push(new TimeInterval(
        DateTime.fromJSDate(b.startTime).setZone(timezone),
        DateTime.fromJSDate(b.endTime).setZone(timezone),
      ));
    }

    // Bookings
    for (const b of bookings) {
      subtractIntervals.push(new TimeInterval(
        DateTime.fromJSDate(b.startTime).setZone(timezone),
        DateTime.fromJSDate(b.endTime).setZone(timezone),
      ));
    }

    availableIntervals = TimeInterval.subtractMany(availableIntervals, subtractIntervals);

    // 5. Generate Slots and Calculate Prices
    const slots = [];
    for (const interval of availableIntervals) {
      let currentStart = interval.start;
      while (currentStart.plus({ minutes: effectiveDuration }) <= interval.end) {
        const slotEnd = currentStart.plus({ minutes: effectiveDuration });

        // Calculate price for this specific slot
        try {
          const pricing = await this.pricingService.calculatePrice(
            facilityId,
            currentStart.toJSDate(),
            slotEnd.toJSDate(),
            timezone,
          );

          slots.push({
            startTime: currentStart.toISO(),
            endTime: slotEnd.toISO(),
            price: pricing.totalPrice,
            currency: pricing.currency,
            breakdown: pricing.breakdown,
          });
        } catch (e) {
          this.logger.warn(`Could not calculate price for slot ${currentStart.toISO()}: ${e.message}`);
          // If no price found, we skip the slot or mark it as un-bookable.
          // For now, we omit it.
        }

        currentStart = slotEnd;
      }
    }

    return {
      facilityId,
      date: dateStr,
      timezone,
      durationMinutes: effectiveDuration,
      slots,
    };
  }
}
