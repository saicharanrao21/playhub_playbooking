import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { CommunicationService } from './communication.service';
import { Events } from '../common/constants/events';
import { CommunicationCategory } from '@prisma/client';

@Injectable()
export class CommunicationEventsListener {
  private readonly logger = new Logger(CommunicationEventsListener.name);

  constructor(private readonly communicationService: CommunicationService) {}

  @OnEvent(Events.BOOKING_CONFIRMED)
  async handleBookingConfirmed(payload: any) {
    this.logger.log(`Dispatching communications for booking confirmed: ${payload.bookingId}`);

    await this.communicationService.sendNotification({
      userId: payload.userId,
      organizationId: payload.organizationId,
      bookingId: payload.bookingId,
      type: 'BOOKING_CONFIRMED',
      category: CommunicationCategory.TRANSACTIONAL,
      idempotencyKey: `booking-confirmed-${payload.bookingId}`,
      variables: {
        customerName: payload.userName || 'Customer',
        venueName: payload.venueName,
        facilityName: payload.facilityName,
        startTime: payload.startTime,
        bookingId: payload.bookingId,
      },
    });
  }

  @OnEvent(Events.BOOKING_CANCELLED)
  async handleBookingCancelled(payload: any) {
    this.logger.log(`Dispatching communications for booking cancelled: ${payload.bookingId}`);

    await this.communicationService.sendNotification({
      userId: payload.userId,
      organizationId: payload.organizationId,
      bookingId: payload.bookingId,
      type: 'BOOKING_CANCELLED',
      category: CommunicationCategory.TRANSACTIONAL,
      idempotencyKey: `booking-cancelled-${payload.bookingId}`,
      variables: {
        customerName: payload.userName || 'Customer',
        venueName: payload.venueName,
        facilityName: payload.facilityName,
        startTime: payload.startTime,
        bookingId: payload.bookingId,
      },
    });
  }

  @OnEvent(Events.PAYMENT_CAPTURED)
  async handlePaymentCaptured(payload: any) {
    this.logger.log(`Dispatching communications for payment success: ${payload.paymentId}`);

    await this.communicationService.sendNotification({
      userId: payload.userId,
      organizationId: payload.organizationId,
      bookingId: payload.bookingId,
      paymentId: payload.paymentId,
      type: 'PAYMENT_SUCCESS',
      category: CommunicationCategory.TRANSACTIONAL,
      idempotencyKey: `payment-success-${payload.paymentId}`,
      variables: {
        customerName: payload.userName || 'Customer',
        bookingId: payload.bookingId,
        amount: payload.amount,
        currency: payload.currency,
      },
    });
  }
}
