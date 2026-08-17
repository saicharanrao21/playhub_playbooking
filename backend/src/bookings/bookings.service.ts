import { Injectable, NotFoundException, ForbiddenException, ConflictException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateBookingDto } from './dto/create-booking.dto';
import { AvailabilityService } from '../availability/availability.service';
import { BookingStatus } from '@prisma/client';
import { DateTime } from 'luxon';
import { TimeInterval } from '../common/utils/time-interval.util';

@Injectable()
export class BookingsService {
  constructor(
    private prisma: PrismaService,
    private availabilityService: AvailabilityService,
  ) {}

  async create(organizationId: string, userId: string, facilityId: string, dto: CreateBookingDto) {
    const requestedStart = DateTime.fromISO(dto.startTime);
    const requestedEnd = DateTime.fromISO(dto.endTime);

    if (!requestedStart.isValid || !requestedEnd.isValid) {
      throw new BadRequestException('Invalid date format');
    }

    if (requestedStart >= requestedEnd) {
      throw new BadRequestException('Start time must be before end time');
    }

    // 1. Verify facility existence and ownership
    const facility = await this.prisma.facility.findFirst({
      where: {
        id: facilityId,
        venue: {
          business: {
            organizationId,
          },
        },
      },
      include: {
        venue: true,
      },
    });

    if (!facility) {
      throw new NotFoundException('Facility not found or unauthorized');
    }

    const requestedInterval = new TimeInterval(requestedStart, requestedEnd);

    // 2. Concurrency-Safe Transaction
    return this.prisma.$transaction(async (tx) => {
      // 2a. Check for overlapping bookings (Locking could be added here if supported/needed)
      // Using a simple read-then-write within a transaction is a baseline.
      // In production PostgreSQL, we'd ideally use SERIALIZABLE isolation or row locks.
      const existingOverlaps = await tx.booking.findFirst({
        where: {
          facilityId,
          status: { in: [BookingStatus.PENDING, BookingStatus.CONFIRMED] },
          AND: [
            { startTime: { lt: requestedEnd.toJSDate() } },
            { endTime: { gt: requestedStart.toJSDate() } },
          ],
        },
      });

      if (existingOverlaps) {
        throw new ConflictException('The requested slot is already booked');
      }

      // 2b. Check Availability (Operating Hours & Blocks)
      const dateStr = requestedStart.setZone(facility.venue.timezone).toISODate();
      const availability = await this.availabilityService.getAvailability(organizationId, facilityId, dateStr!);

      const isAvailable = availability.availableIntervals.some(interval =>
        interval.contains(requestedInterval)
      );

      if (!isAvailable) {
        throw new ConflictException('Requested time is outside operational hours or blocked');
      }

      // 3. Create Booking
      return tx.booking.create({
        data: {
          organizationId,
          userId,
          facilityId,
          startTime: requestedStart.toJSDate(),
          endTime: requestedEnd.toJSDate(),
          status: BookingStatus.CONFIRMED, // Direct confirmation for this phase
        },
      });
    });
  }

  async findOne(organizationId: string, id: string) {
    const booking = await this.prisma.booking.findFirst({
      where: { id, organizationId },
      include: {
        facility: {
          include: { venue: true }
        },
        user: {
          select: { id: true, email: true, fullName: true }
        }
      }
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    return booking;
  }

  async findAll(organizationId: string, filters: { userId?: string; facilityId?: string }) {
    return this.prisma.booking.findMany({
      where: {
        organizationId,
        ...(filters.userId ? { userId: filters.userId } : {}),
        ...(filters.facilityId ? { facilityId: filters.facilityId } : {}),
      },
      orderBy: { startTime: 'desc' },
      include: {
        facility: true,
      }
    });
  }

  async cancel(organizationId: string, id: string) {
    const booking = await this.findOne(organizationId, id);

    if (booking.status === BookingStatus.CANCELLED) {
       return booking;
    }

    return this.prisma.booking.update({
      where: { id },
      data: {
        status: BookingStatus.CANCELLED,
      },
    });
  }
}
