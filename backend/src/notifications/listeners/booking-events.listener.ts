import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { NotificationsService } from '../notifications.service';
import { NotificationType } from '@prisma/client';
import { Events } from '../../common/constants/events';
import { OrganizationsService } from '../../organizations/organizations.service';

@Injectable()
export class BookingEventsListener {
  private readonly logger = new Logger(BookingEventsListener.name);

  constructor(
    private readonly notificationsService: NotificationsService,
    private readonly organizationsService: OrganizationsService,
  ) {}

  @OnEvent(Events.BOOKING_CREATED)
  async handleBookingCreated(payload: any) {
    this.logger.log(`Handling booking created event: ${payload.bookingId}`);

    // 1. Notify Customer
    await this.notificationsService.create({
      organizationId: payload.organizationId,
      userId: payload.userId,
      bookingId: payload.bookingId,
      type: NotificationType.BOOKING_CREATED,
      title: 'Booking Initiated',
      message: `Your booking for ${payload.facilityName} is being processed.`,
      payload: { ...payload },
    });

    // 2. Notify Partner Owners/Managers
    try {
      const members = await this.organizationsService.getMembers(payload.organizationId);
      for (const member of members) {
        // Simple heuristic: notify everyone in the organization for now
        // In real app, filter by role (OWNER/MANAGER)
        await this.notificationsService.create({
          organizationId: payload.organizationId,
          userId: member.userId,
          bookingId: payload.bookingId,
          type: NotificationType.BOOKING_CREATED,
          title: 'New Booking Received',
          message: `New booking request for ${payload.facilityName}. Please review and approve.`,
          payload: { ...payload },
        });
      }
    } catch (e) {
      this.logger.error('Failed to notify partners', e);
    }
  }

  @OnEvent(Events.BOOKING_ACCEPTED)
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

  @OnEvent(Events.BOOKING_REJECTED)
  async handleBookingRejected(payload: any) {
    this.logger.log(`Handling booking rejected event: ${payload.bookingId}`);
    await this.notificationsService.create({
      organizationId: payload.organizationId,
      userId: payload.userId,
      bookingId: payload.bookingId,
      type: NotificationType.BOOKING_CANCELLED,
      title: 'Booking Rejected',
      message: `Your booking for ${payload.facilityName} was declined by the venue. Reason: ${payload.reason || 'Not specified'}.`,
      payload: { ...payload },
    });
  }

  @OnEvent(Events.BOOKING_ARRIVED)
  async handleBookingArrived(payload: any) {
    this.logger.log(`Handling booking arrived (check-in) event: ${payload.bookingId}`);
    await this.notificationsService.create({
      organizationId: payload.organizationId,
      userId: payload.userId,
      bookingId: payload.bookingId,
      type: NotificationType.SYSTEM_ALERT,
      title: 'Checked In',
      message: `You have successfully checked in for ${payload.facilityName}. Enjoy your game!`,
      payload: { ...payload },
    });
  }
}
