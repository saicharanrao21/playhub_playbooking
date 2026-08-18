import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { NotificationsService } from '../notifications.service';
import { NotificationType } from '@prisma/client';
import { Events } from '../../common/constants/events';

@Injectable()
export class BookingEventsListener {
  private readonly logger = new Logger(BookingEventsListener.name);

  constructor(private readonly notificationsService: NotificationsService) {}

  @OnEvent(Events.BOOKING_CREATED)
  async handleBookingCreated(payload: any) {
    this.logger.log(`Handling booking created event: ${payload.bookingId}`);
    await this.notificationsService.create({
      organizationId: payload.organizationId,
      userId: payload.userId,
      bookingId: payload.bookingId,
      type: NotificationType.BOOKING_CREATED,
      title: 'Booking Initiated',
      message: `Your booking for ${payload.facilityName} is being processed.`,
      payload: { ...payload },
    });
  }

  @OnEvent(Events.BOOKING_CONFIRMED)
  async handleBookingConfirmed(payload: any) {
    this.logger.log(`Handling booking confirmed event: ${payload.bookingId}`);
    await this.notificationsService.create({
      organizationId: payload.organizationId,
      userId: payload.userId,
      bookingId: payload.bookingId,
      type: NotificationType.BOOKING_CONFIRMED,
      title: 'Booking Confirmed!',
      message: `Great news! Your booking for ${payload.facilityName} is confirmed.`,
      payload: { ...payload },
    });
  }

  @OnEvent(Events.BOOKING_CANCELLED)
  async handleBookingCancelled(payload: any) {
    this.logger.log(`Handling booking cancelled event: ${payload.bookingId}`);
    await this.notificationsService.create({
      organizationId: payload.organizationId,
      userId: payload.userId,
      bookingId: payload.bookingId,
      type: NotificationType.BOOKING_CANCELLED,
      title: 'Booking Cancelled',
      message: `Your booking for ${payload.facilityName} has been cancelled.`,
      payload: { ...payload },
    });
  }
}
