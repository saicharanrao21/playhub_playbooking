import { Injectable, NotFoundException, ConflictException, ForbiddenException, BadRequestException, Logger, Inject } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { PrismaService } from '../prisma/prisma.service';
import { IPaymentProvider, PAYMENT_PROVIDER } from './interfaces/payment-provider.interface';
import { CreatePaymentOrderDto } from './dto/create-payment-order.dto';
import { VerifyPaymentDto } from './dto/verify-payment.dto';
import { PaymentStatus, BookingStatus, PaymentProvider } from '@prisma/client';
import { Events } from '../common/constants/events';

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);

  constructor(
    private prisma: PrismaService,
    @Inject(PAYMENT_PROVIDER) private provider: IPaymentProvider,
    private eventEmitter: EventEmitter2,
  ) {}

  async createOrder(organizationId: string, userId: string, dto: CreatePaymentOrderDto) {
    const booking = await this.prisma.booking.findFirst({
      where: { id: dto.bookingId, organizationId },
      include: { payments: true }
    });

    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    if (booking.status === BookingStatus.CANCELLED) {
      throw new BadRequestException('Cannot pay for a cancelled booking');
    }

    // Check for existing successful or pending payments
    const activePayment = booking.payments.find(p =>
      p.status === PaymentStatus.CAPTURED || p.status === PaymentStatus.AUTHORIZED
    );
    if (activePayment) {
      throw new ConflictException('Booking is already paid or authorized');
    }

    // Amount integrity: server-calculated
    // For this phase, we assume totalPrice is set. If not, we'd calculate it.
    if (!booking.totalPrice) {
       throw new BadRequestException('Booking has no price associated');
    }

    const amountInMinorUnits = Math.round(Number(booking.totalPrice) * 100);

    const order = await this.provider.createOrder({
      amount: amountInMinorUnits,
      currency: booking.currency || 'INR',
      receipt: booking.id,
      notes: { organizationId, bookingId: booking.id, userId }
    });

    return this.prisma.payment.create({
      data: {
        organizationId,
        bookingId: booking.id,
        amount: booking.totalPrice,
        currency: booking.currency || 'INR',
        status: PaymentStatus.INITIATED,
        provider: PaymentProvider.MOCK, // Future: read from config/org
        providerOrderId: order.id,
      }
    });
  }

  async verifyPayment(organizationId: string, userId: string, dto: VerifyPaymentDto) {
    const payment = await this.prisma.payment.findUnique({
      where: { providerOrderId: dto.providerOrderId },
      include: { booking: true }
    });

    if (!payment || payment.organizationId !== organizationId) {
      throw new NotFoundException('Payment record not found');
    }

    if (payment.status === PaymentStatus.CAPTURED) {
       return { status: 'success', booking: payment.booking };
    }

    // Authoritative verification
    const isValid = this.provider.verifySignature(dto, dto.signature);
    if (!isValid) {
      throw new BadRequestException('Invalid payment signature');
    }

    return this.prisma.$transaction(async (tx) => {
      // 1. Update Payment record
      const updatedPayment = await tx.payment.update({
        where: { id: payment.id },
        data: {
          status: PaymentStatus.CAPTURED,
          providerPaymentId: dto.providerPaymentId,
          providerSignature: dto.signature,
          metadata: dto.metadata,
        }
      });

      // 2. Update Booking record only if not cancelled
      const updatedBooking = await tx.booking.update({
        where: {
          id: payment.bookingId,
          status: { not: BookingStatus.CANCELLED }
        },
        data: {
          status: BookingStatus.CONFIRMED,
        }
      });

      // 3. Audit
      await tx.auditLog.create({
        data: {
          userId,
          action: 'payment:captured',
          resource: 'booking',
          resourceId: updatedBooking.id,
          status: 'success',
          payload: { paymentId: updatedPayment.id, providerOrderId: dto.providerOrderId }
        }
      });

      this.eventEmitter.emit(Events.PAYMENT_CAPTURED, {
        paymentId: updatedPayment.id,
        bookingId: updatedBooking.id,
        organizationId: updatedPayment.organizationId,
        userId: userId,
        amount: updatedPayment.amount,
      });

      // confirmed status already updated in DB, emit event for notification
      this.eventEmitter.emit(Events.BOOKING_CONFIRMED, {
        bookingId: updatedBooking.id,
        organizationId: updatedBooking.organizationId,
        userId: updatedBooking.userId,
        facilityName: 'facility', // Simplified for foundation
        startTime: updatedBooking.startTime,
      });

      return { status: 'success', booking: updatedBooking };
    });
  }

  async handleWebhook(provider: string, payload: any, signature: string) {
    this.logger.log(`Received webhook for ${provider}`);

    // 1. Verify Signature (Mock logic for now)
    const isValid = this.provider.verifySignature(payload, signature);
    if (!isValid) {
      this.logger.warn(`Invalid webhook signature from ${provider}`);
      throw new BadRequestException('Invalid webhook signature');
    }

    // 2. Extract provider identifiers (Standardizing for this foundation)
    const providerOrderId = payload.order_id || payload.data?.object?.id;
    const providerPaymentId = payload.payment_id || payload.data?.object?.payment_intent;
    const eventType = payload.event; // e.g. 'payment.captured'

    if (!providerOrderId) {
      return { status: 'ignored', reason: 'No order ID found' };
    }

    // 3. Process success events
    if (eventType === 'payment.captured' || eventType === 'checkout.session.completed') {
      const payment = await this.prisma.payment.findUnique({
        where: { providerOrderId },
        include: { booking: true }
      });

      if (!payment) {
        this.logger.error(`Payment record not found for provider order: ${providerOrderId}`);
        return { status: 'error', reason: 'Payment not found' };
      }

      if (payment.status === PaymentStatus.CAPTURED) {
        return { status: 'noop', reason: 'Already processed' };
      }

      return this.prisma.$transaction(async (tx) => {
        // Atomic update with status check (Deduplication)
        const updatedPayment = await tx.payment.update({
          where: { id: payment.id, status: { not: PaymentStatus.CAPTURED } },
          data: {
            status: PaymentStatus.CAPTURED,
            providerPaymentId,
          }
        }).catch(() => null);

        if (!updatedPayment) return { status: 'noop', reason: 'Concurrent update' };

        await tx.booking.update({
          where: {
            id: payment.bookingId,
            status: { not: BookingStatus.CANCELLED }
          },
          data: { status: BookingStatus.CONFIRMED }
        }).catch(() => null);

        await tx.auditLog.create({
          data: {
            userId: payment.booking.userId,
            action: 'payment:webhook_captured',
            resource: 'booking',
            resourceId: payment.bookingId,
            status: 'success',
            payload: { provider, eventType }
          }
        });

        this.eventEmitter.emit(Events.PAYMENT_CAPTURED, {
          paymentId: updatedPayment.id,
          bookingId: payment.bookingId,
          organizationId: payment.organizationId,
          userId: payment.booking.userId,
          amount: payment.amount,
        });

        this.eventEmitter.emit(Events.BOOKING_CONFIRMED, {
          bookingId: payment.bookingId,
          organizationId: payment.organizationId,
          userId: payment.booking.userId,
          facilityName: 'facility',
          startTime: payment.booking.startTime,
        });

        return { status: 'success' };
      });
    }

    return { received: true };
  }
}
