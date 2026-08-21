import { Injectable, NotFoundException, ForbiddenException, ConflictException, BadRequestException } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { PrismaService } from '../prisma/prisma.service';
import { CreateBookingDto } from './dto/create-booking.dto';
import { RescheduleBookingDto } from './dto/reschedule-booking.dto';
import { AvailabilityService } from '../availability/availability.service';
import { BookingStatus, VenueStatus, FacilityStatus, PaymentStatus } from '@prisma/client';
import { DateTime } from 'luxon';
import { TimeInterval } from '../common/utils/time-interval.util';
import { Events } from '../common/constants/events';

@Injectable()
export class BookingsService {
  constructor(
    private prisma: PrismaService,
    private availabilityService: AvailabilityService,
    private eventEmitter: EventEmitter2,
  ) {}

  /**
   * Validates if a transition from current status to next status is allowed.
   */
  private validateStatusTransition(current: BookingStatus, next: BookingStatus) {
    if (current === next) return;

    const allowedTransitions: Record<BookingStatus, BookingStatus[]> = {
      [BookingStatus.PENDING]: [BookingStatus.CONFIRMED, BookingStatus.CANCELLED],
      [BookingStatus.CONFIRMED]: [BookingStatus.COMPLETED, BookingStatus.CANCELLED],
      [BookingStatus.CANCELLED]: [], // Terminal state
      [BookingStatus.COMPLETED]: [], // Terminal state
    };

    if (!allowedTransitions[current].includes(next)) {
      throw new BadRequestException(`Invalid booking status transition from ${current} to ${next}`);
    }
  }

  async create(organizationId: string, userId: string, facilityId: string, dto: CreateBookingDto, idempotencyKey?: string) {
    const requestedStart = DateTime.fromISO(dto.startTime);
    const requestedEnd = DateTime.fromISO(dto.endTime);

    if (!requestedStart.isValid || !requestedEnd.isValid) {
      throw new BadRequestException('Invalid date format');
    }

    if (requestedStart >= requestedEnd) {
      throw new BadRequestException('Start time must be before end time');
    }

    if (requestedStart < DateTime.now()) {
      throw new BadRequestException('Cannot create a booking in the past');
    }

    // 1. Verify facility existence, status and ownership
    const facility = await this.prisma.facility.findFirst({
      where: {
        id: facilityId,
        status: FacilityStatus.ACTIVE,
        venue: {
          status: VenueStatus.ACTIVE,
          business: {
            organizationId,
          },
        },
      },
      include: {
        venue: true,
        pricingRules: {
          orderBy: { createdAt: 'desc' },
          take: 1,
        },
      },
    });

    if (!facility) {
      throw new NotFoundException('Facility not found or unauthorized');
    }

    const requestedInterval = new TimeInterval(requestedStart, requestedEnd);

    // Calculate total price based on duration and basePrice
    const durationInHours = requestedEnd.diff(requestedStart, 'hours').hours;
    const pricingRule = facility.pricingRules[0];
    if (!pricingRule) {
      throw new BadRequestException('No pricing rule found for this facility');
    }
    const totalPrice = Number(pricingRule.basePrice) * durationInHours;

    // 2. Concurrency-Safe Transaction
    return this.prisma.$transaction(async (tx) => {
      // 2a. Idempotency check
      if (idempotencyKey) {
        const existing = await tx.booking.findUnique({
          where: { idempotencyKey },
        });
        if (existing) {
          if (existing.userId === userId && existing.organizationId === organizationId) {
            return existing;
          }
          throw new ConflictException('Idempotency key mismatch');
        }
      }

      // 2b. Check for overlapping bookings
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

      // 2c. Check Availability (Operating Hours & Blocks) - passing tx to ensure consistent read
      const dateStr = requestedStart.setZone(facility.venue.timezone).toISODate();
      const availability = await this.availabilityService.getAvailability(organizationId, facilityId, dateStr!, 60, tx);

      const isAvailable = availability.availableIntervals.some(interval =>
        interval.contains(requestedInterval)
      );

      if (!isAvailable) {
        throw new ConflictException('Requested time is outside operational hours or blocked');
      }

      // 3. Create Booking - Start as PENDING (awaiting payment confirmation)
      const booking = await tx.booking.create({
        data: {
          organizationId,
          userId,
          facilityId,
          startTime: requestedStart.toJSDate(),
          endTime: requestedEnd.toJSDate(),
          status: BookingStatus.PENDING,
          totalPrice,
          currency: pricingRule.currency,
          idempotencyKey,
        },
      });

      this.eventEmitter.emit(Events.BOOKING_CREATED, {
        bookingId: booking.id,
        organizationId: booking.organizationId,
        userId: booking.userId,
        facilityName: facility.name,
        startTime: booking.startTime,
      });

      return booking;
    }, {
      isolationLevel: 'Serializable',
    });
  }

  async findOne(organizationId: string, id: string, userId?: string) {
    const booking = await this.prisma.booking.findFirst({
      where: {
        id,
        organizationId,
        ...(userId ? { userId } : {}),
      },
      include: {
        facility: {
          include: { venue: true }
        },
        user: {
          select: {
            id: true,
            email: true,
            fullName: true,
            phoneNumber: true,
          }
        },
        payments: true,
      }
    });

    if (!booking) {
      throw new NotFoundException('Booking not found or access denied');
    }

    return booking;
  }

  async findAll(organizationId: string, filters: { userId?: string; facilityId?: string; skip?: number; take?: number }) {
    const [items, total] = await Promise.all([
      this.prisma.booking.findMany({
        where: {
          organizationId,
          ...(filters.userId ? { userId: filters.userId } : {}),
          ...(filters.facilityId ? { facilityId: filters.facilityId } : {}),
        },
        orderBy: { startTime: 'desc' },
        include: {
          facility: true,
        },
        skip: filters.skip,
        take: filters.take,
      }),
      this.prisma.booking.count({
        where: {
          organizationId,
          ...(filters.userId ? { userId: filters.userId } : {}),
          ...(filters.facilityId ? { facilityId: filters.facilityId } : {}),
        },
      }),
    ]);

    return { items, total };
  }

  async cancel(organizationId: string, id: string, reason?: string, userId?: string) {
    const booking = await this.findOne(organizationId, id, userId);

    if (booking.status === BookingStatus.CANCELLED) {
      return booking;
    }

    this.validateStatusTransition(booking.status, BookingStatus.CANCELLED);

    return this.prisma.$transaction(async (tx) => {
      // Atomic re-check of status within transaction
      const updatedBooking = await tx.booking.update({
        where: {
          id,
          status: { in: [BookingStatus.PENDING, BookingStatus.CONFIRMED] }
        },
        data: {
          status: BookingStatus.CANCELLED,
          cancelledAt: new Date(),
          cancelReason: reason,
        },
        include: { facility: true, payments: true }
      });

      // Update associated non-captured payments to CANCELLED
      await tx.payment.updateMany({
        where: {
          bookingId: id,
          status: { notIn: [PaymentStatus.CAPTURED, PaymentStatus.REFUNDED] }
        },
        data: { status: PaymentStatus.CANCELLED }
      });

      this.eventEmitter.emit(Events.BOOKING_CANCELLED, {
        bookingId: updatedBooking.id,
        organizationId: updatedBooking.organizationId,
        userId: updatedBooking.userId,
        facilityName: updatedBooking.facility.name,
        startTime: updatedBooking.startTime,
        hasCapturedPayments: updatedBooking.payments.some(p => p.status === PaymentStatus.CAPTURED)
      });

      return updatedBooking;
    }, { isolationLevel: 'Serializable' });
  }

  async reschedule(organizationId: string, bookingId: string, dto: RescheduleBookingDto, userId?: string) {
    const newStart = DateTime.fromISO(dto.newStartTime);
    const newEnd = DateTime.fromISO(dto.newEndTime);

    if (!newStart.isValid || !newEnd.isValid) {
      throw new BadRequestException('Invalid date format');
    }

    if (newStart >= newEnd) {
      throw new BadRequestException('Start time must be before end time');
    }

    if (newStart < DateTime.now()) {
      throw new BadRequestException('Cannot reschedule to a past time');
    }

    const booking = await this.findOne(organizationId, bookingId, userId);

    if (booking.facility.status !== FacilityStatus.ACTIVE ||
        booking.facility.venue.status !== VenueStatus.ACTIVE) {
      throw new BadRequestException('Facility or Venue is no longer active');
    }

    if (booking.status !== BookingStatus.CONFIRMED && booking.status !== BookingStatus.PENDING) {
      throw new BadRequestException('Only active bookings can be rescheduled');
    }

    // Optimization: return immediately if new slot is same as current
    if (DateTime.fromJSDate(booking.startTime).equals(newStart) &&
        DateTime.fromJSDate(booking.endTime).equals(newEnd)) {
      return booking;
    }

    const requestedInterval = new TimeInterval(newStart, newEnd);

    return this.prisma.$transaction(async (tx) => {
      // 1. Check for overlaps excluding the current booking
      const existingOverlaps = await tx.booking.findFirst({
        where: {
          facilityId: booking.facilityId,
          id: { not: booking.id },
          status: { in: [BookingStatus.PENDING, BookingStatus.CONFIRMED] },
          AND: [
            { startTime: { lt: newEnd.toJSDate() } },
            { endTime: { gt: newStart.toJSDate() } },
          ],
        },
      });

      if (existingOverlaps) {
        throw new ConflictException('The requested new slot is already booked');
      }

      // 2. Check Availability passing tx
      const dateStr = newStart.setZone(booking.facility.venue.timezone).toISODate();
      const availability = await this.availabilityService.getAvailability(organizationId, booking.facilityId, dateStr!, 60, tx);

      const isAvailable = availability.availableIntervals.some(interval =>
        interval.contains(requestedInterval)
      );

      if (!isAvailable) {
        throw new ConflictException('Requested time is outside operational hours or blocked');
      }

      // 3. Update Booking
      const updatedBooking = await tx.booking.update({
        where: { id: bookingId },
        data: {
          startTime: newStart.toJSDate(),
          endTime: newEnd.toJSDate(),
        },
        include: { facility: true }
      });

      this.eventEmitter.emit(Events.BOOKING_RESCHEDULED, {
        bookingId: updatedBooking.id,
        organizationId: updatedBooking.organizationId,
        userId: updatedBooking.userId,
        facilityName: updatedBooking.facility.name,
        startTime: updatedBooking.startTime,
      });

      return updatedBooking;
    }, {
      isolationLevel: 'Serializable',
    });
  }
}
