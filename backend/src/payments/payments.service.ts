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

  private readonly TERMINAL_STATES: PaymentStatus[] = [
    PaymentStatus.CAPTURED,
    PaymentStatus.FAILED,
    PaymentStatus.CANCELLED,
    PaymentStatus.REFUNDED,
  ];

  constructor(
    private prisma: PrismaService,
    @Inject(PAYMENT_PROVIDER) private provider: IPaymentProvider,
    private eventEmitter: EventEmitter2,
  ) {}

  /**
   * Validates if a transition from current status to next status is allowed.
   */
  private canTransition(current: PaymentStatus, next: PaymentStatus): boolean {
    if (current === next) return true;
    if (this.TERMINAL_STATES.includes(current) && next !== PaymentStatus.REFUNDED) {
      return false;
    }
    if (current === PaymentStatus.CAPTURED && next === PaymentStatus.REFUNDED) {
      return true;
    }

    const allowed: Record<PaymentStatus, PaymentStatus[]> = {
      [PaymentStatus.INITIATED]: [PaymentStatus.PENDING, PaymentStatus.AUTHORIZED, PaymentStatus.CAPTURED, PaymentStatus.FAILED, PaymentStatus.CANCELLED],
      [PaymentStatus.PENDING]: [PaymentStatus.AUTHORIZED, PaymentStatus.CAPTURED, PaymentStatus.FAILED, PaymentStatus.CANCELLED],
      [PaymentStatus.AUTHORIZED]: [PaymentStatus.CAPTURED, PaymentStatus.FAILED, PaymentStatus.CANCELLED],
      [PaymentStatus.CAPTURED]: [PaymentStatus.REFUNDED],
      [PaymentStatus.FAILED]: [],
      [PaymentStatus.CANCELLED]: [],
      [PaymentStatus.REFUNDED]: [],
    };

    return allowed[current]?.includes(next) || false;
  }

  async createOrder(organizationId: string, userId: string, dto: CreatePaymentOrderDto, idempotencyKey?: string) {
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

    // 1. Idempotency Check
    if (idempotencyKey) {
      const existing = await this.prisma.payment.findUnique({
        where: { idempotencyKey }
      });
      if (existing) {
        if (existing.bookingId !== dto.bookingId || existing.organizationId !== organizationId) {
          throw new ConflictException('Idempotency key mismatch');
        }
        return existing;
      }
    }

    // 2. Check for existing successful or authorized payments
    const activePayment = booking.payments.find(p =>
      p.status === PaymentStatus.CAPTURED || p.status === PaymentStatus.AUTHORIZED
    );
    if (activePayment) {
      throw new ConflictException('Booking is already paid or authorized');
    }

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
        provider: PaymentProvider.MOCK,
        providerOrderId: order.id,
        idempotencyKey,
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

    if (!this.canTransition(payment.status, PaymentStatus.CAPTURED)) {
      throw new BadRequestException(`Invalid state transition from ${payment.status} to CAPTURED`);
    }

    const isValid = this.provider.verifySignature(dto, dto.signature);
    if (!isValid) {
      throw new BadRequestException('Invalid payment signature');
    }

    return this.prisma.$transaction(async (tx) => {
      // Re-verify status inside transaction for concurrency safety
      const latestPayment = await tx.payment.findUnique({
        where: { id: payment.id }
      });
      if (latestPayment.status === PaymentStatus.CAPTURED) {
        return { status: 'success', booking: payment.booking };
      }

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
      }).catch(() => {
        this.logger.warn(`Attempted to confirm a cancelled booking: ${payment.bookingId}`);
        return null;
      });

      // 3. Audit
      await tx.auditLog.create({
        data: {
          userId,
          action: 'payment:captured',
          resource: 'payment',
          resourceId: updatedPayment.id,
          status: 'success',
          payload: {
            bookingId: payment.bookingId,
            previousStatus: payment.status,
            newStatus: updatedPayment.status
          }
        }
      });

      this.eventEmitter.emit(Events.PAYMENT_CAPTURED, {
        paymentId: updatedPayment.id,
        bookingId: payment.bookingId,
        organizationId: updatedPayment.organizationId,
        userId: userId,
        amount: updatedPayment.amount,
      });

      if (updatedBooking) {
        this.eventEmitter.emit(Events.BOOKING_CONFIRMED, {
          bookingId: updatedBooking.id,
          organizationId: updatedBooking.organizationId,
          userId: updatedBooking.userId,
          facilityName: 'facility',
          startTime: updatedBooking.startTime,
        });
      }

      return { status: 'success', booking: updatedBooking || payment.booking };
    }, { isolationLevel: 'Serializable' });
  }

  async handleWebhook(provider: string, payload: any, signature: string) {
    this.logger.log(`Received webhook for ${provider}`);

    const isValid = this.provider.verifySignature(payload, signature);
    if (!isValid) {
      this.logger.warn(`Invalid webhook signature from ${provider}`);
      throw new BadRequestException('Invalid webhook signature');
    }

    const providerOrderId = payload.order_id || payload.data?.object?.id;
    const providerPaymentId = payload.payment_id || payload.data?.object?.payment_intent;
    const eventType = payload.event;

    if (!providerOrderId) {
      return { status: 'ignored', reason: 'No order ID found' };
    }

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
        const latestPayment = await tx.payment.findUnique({ where: { id: payment.id } });
        if (!this.canTransition(latestPayment.status, PaymentStatus.CAPTURED)) {
          return { status: 'noop', reason: `Invalid transition from ${latestPayment.status}` };
        }

        const updatedPayment = await tx.payment.update({
          where: { id: payment.id },
          data: {
            status: PaymentStatus.CAPTURED,
            providerPaymentId,
          }
        });

        if (!updatedPayment) return { status: 'noop', reason: 'Concurrent update' };

        const updatedBooking = await tx.booking.update({
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
            resource: 'payment',
            resourceId: payment.id,
            status: 'success',
            payload: { provider, eventType, previousStatus: payment.status }
          }
        });

        this.eventEmitter.emit(Events.PAYMENT_CAPTURED, {
          paymentId: updatedPayment.id,
          bookingId: payment.bookingId,
          organizationId: payment.organizationId,
          userId: payment.booking.userId,
          amount: payment.amount,
        });

        if (updatedBooking) {
          this.eventEmitter.emit(Events.BOOKING_CONFIRMED, {
            bookingId: payment.bookingId,
            organizationId: payment.organizationId,
            userId: payment.booking.userId,
            facilityName: 'facility',
            startTime: payment.booking.startTime,
          });
        }

        return { status: 'success' };
      }, { isolationLevel: 'Serializable' });
    }

    return { received: true };
  }
}
