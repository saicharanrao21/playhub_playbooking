import {
  Injectable,
  Logger,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { PaymentProviderFactory } from '../payments/providers/payment-provider.factory';
import { FinanceService } from '../finance/finance.service';
import { QueueService } from '../queues/queue.service';
import { AuditService } from '../common/services/audit.service';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { Events } from '../common/constants/events';
import { PaymentProvider, PaymentStatus, BookingStatus, Prisma } from '@prisma/client';
import { WebhookStatus } from './webhooks.types';
import { MetricsService } from '../observability/metrics.service';
import { Optional } from '@nestjs/common';

@Injectable()
export class WebhooksService {
  private readonly logger = new Logger(WebhooksService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly providerFactory: PaymentProviderFactory,
    private readonly financeService: FinanceService,
    private readonly queueService: QueueService,
    private readonly auditService: AuditService,
    private readonly eventEmitter: EventEmitter2,
    @Optional() private readonly metricsService?: MetricsService,
  ) {}

  /**
   * Fast, idempotent webhook receiver endpoint handler (<200ms ACK).
   * 1. Signature Verification.
   * 2. Atomic persistence & deduplication in PostgreSQL.
   * 3. BullMQ queue submission for asynchronous domain processing.
   */
  async receiveWebhook(
    providerType: string,
    payload: any,
    signature: string,
    rawBody?: string,
  ) {
    const pType = providerType.toUpperCase() as PaymentProvider;
    this.logger.log(`Receiving ${pType} webhook event`);

    // 1. Signature Verification
    const provider = this.providerFactory.getProvider(pType);
    const bodyToVerify = rawBody || JSON.stringify(payload);
    const isValidSignature = provider.verifyWebhookSignature(bodyToVerify, signature);

    if (!isValidSignature) {
      this.logger.warn(`Invalid ${pType} webhook signature received`);
      await this.auditService.record({
        action: 'webhook:invalid_signature',
        resource: 'webhook_event',
        payload: { provider: pType, signature },
        status: 'failure',
      });
      throw new BadRequestException('Invalid webhook signature');
    }

    const providerEventId =
      payload.id ||
      payload.event_id ||
      `evt_${Date.now()}_${Math.random().toString(36).substring(2, 8)}`;
    const eventType = payload.event || payload.type || 'unknown.event';

    // 2. Atomic Persistence & Idempotency Check in PostgreSQL
    let webhookEvent;
    try {
      webhookEvent = await this.prisma.paymentWebhookEvent.create({
        data: {
          provider: pType,
          providerEventId,
          eventType,
          signature: signature ? signature.substring(0, 200) : null,
          status: WebhookStatus.QUEUED,
          payload,
        },
      });
    } catch (e) {
      if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
        // Unique constraint violation: duplicate (provider, providerEventId)
        this.logger.log(`Duplicate webhook event [${pType}:${providerEventId}] received. Acknowledging duplicate.`);

        await this.auditService.record({
          action: 'webhook:duplicate_ignored',
          resource: 'webhook_event',
          payload: { provider: pType, providerEventId },
          status: 'success',
        });

        return {
          received: true,
          status: 'ignored',
          reason: 'Duplicate webhook event already recorded',
        };
      }
      throw e;
    }

    // 3. Enqueue Webhook Job to BullMQ Queue
    await this.queueService.addWebhookJob(
      'process-webhook',
      { webhookEventId: webhookEvent.id },
      { jobId: webhookEvent.id },
    );

    if (this.metricsService) {
      this.metricsService.webhooksTotal.inc({ provider: pType, status: 'queued' });
    }

    return {
      received: true,
      eventId: providerEventId,
      status: 'queued',
    };
  }

  /**
   * Asynchronous BullMQ worker handler for domain processing.
   * State Machine: QUEUED -> PROCESSING -> PROCESSED | FAILED
   */
  async processWebhookEvent(webhookEventId: string) {
    const event = await this.prisma.paymentWebhookEvent.findUnique({
      where: { id: webhookEventId },
    });

    if (!event) {
      this.logger.warn(`Webhook event [${webhookEventId}] not found in DB`);
      return;
    }

    if (event.status === WebhookStatus.PROCESSED) {
      this.logger.log(`Webhook event [${event.id}] already PROCESSED. Skipping.`);
      return;
    }

    // Atomically mark PROCESSING
    await this.prisma.paymentWebhookEvent.update({
      where: { id: webhookEventId },
      data: {
        status: WebhookStatus.PROCESSING,
        processingStartedAt: new Date(),
      },
    });

    try {
      const payload = event.payload as any;
      const provider = event.provider;
      const eventType = event.eventType;

      const providerOrderId =
        payload.order_id ||
        payload.data?.object?.id ||
        payload.payload?.payment?.entity?.order_id;
      const providerPaymentId =
        payload.payment_id ||
        payload.data?.object?.payment_intent ||
        payload.payload?.payment?.entity?.id;

      // Handle Captured Payment Events
      if (['payment.captured', 'checkout.session.completed', 'payment_intent.succeeded'].includes(eventType)) {
        await this.processPaymentCapturedEvent(event, providerOrderId, providerPaymentId, payload);
      } else if (['refund.processed', 'charge.refunded'].includes(eventType)) {
        await this.processRefundEvent(event, providerOrderId, providerPaymentId, payload);
      } else {
        // Unhandled / Informational Event
        await this.prisma.paymentWebhookEvent.update({
          where: { id: webhookEventId },
          data: {
            status: WebhookStatus.IGNORED,
            processedAt: new Date(),
          },
        });
      }
    } catch (err) {
      this.logger.error(`Webhook processing error for [${webhookEventId}]: ${err.message}`, err.stack);

      await this.prisma.paymentWebhookEvent.update({
        where: { id: webhookEventId },
        data: {
          status: WebhookStatus.FAILED,
          failedAt: new Date(),
          retryCount: { increment: 1 },
          lastError: err.message,
        },
      });

      throw err; // Allow BullMQ worker retry
    }
  }

  private async processPaymentCapturedEvent(
    event: any,
    providerOrderId: string,
    providerPaymentId: string,
    payload: any,
  ) {
    const payment = await this.prisma.payment.findFirst({
      where: { OR: [{ providerOrderId }, { providerPaymentId }] },
      include: { booking: true },
    });

    if (!payment) {
      this.logger.error(`Payment record not found for provider order/payment: ${providerOrderId || providerPaymentId}`);
      await this.prisma.paymentWebhookEvent.update({
        where: { id: event.id },
        data: {
          status: WebhookStatus.FAILED,
          lastError: 'Payment record not found',
          failedAt: new Date(),
        },
      });
      return;
    }

    if (payment.status === PaymentStatus.CAPTURED) {
      await this.prisma.paymentWebhookEvent.update({
        where: { id: event.id },
        data: {
          status: WebhookStatus.PROCESSED,
          paymentId: payment.id,
          organizationId: payment.organizationId,
          processedAt: new Date(),
        },
      });
      return;
    }

    // Atomic Database Transaction
    const result = await this.prisma.$transaction(
      async (tx) => {
        const latestPayment = await tx.payment.findUnique({ where: { id: payment.id } });
        if (latestPayment.status === PaymentStatus.CAPTURED) {
          return { transitionedBooking: false };
        }

        const updatedPayment = await tx.payment.update({
          where: { id: payment.id },
          data: {
            status: PaymentStatus.CAPTURED,
            providerPaymentId: providerPaymentId || latestPayment.providerPaymentId,
          },
        });

        const updatedBooking = await tx.booking
          .update({
            where: {
              id: payment.bookingId,
              status: { in: [BookingStatus.PENDING] },
            },
            data: { status: BookingStatus.CONFIRMED },
          })
          .catch(() => null);

        return { payment: updatedPayment, transitionedBooking: !!updatedBooking };
      },
      { isolationLevel: 'Serializable' },
    );

    // Record Immutable Financial Ledger Event (Idempotent via pay_${payment.id})
    await this.financeService.recordPayment({
      paymentId: payment.id,
      bookingId: payment.bookingId,
      organizationId: payment.organizationId,
      amount: payment.amount,
      userId: payment.booking.userId,
    });

    // Update WebhookEvent to PROCESSED
    await this.prisma.paymentWebhookEvent.update({
      where: { id: event.id },
      data: {
        status: WebhookStatus.PROCESSED,
        paymentId: payment.id,
        organizationId: payment.organizationId,
        processedAt: new Date(),
      },
    });

    // Emit Domain Events
    this.eventEmitter.emit(Events.PAYMENT_CAPTURED, {
      paymentId: payment.id,
      bookingId: payment.bookingId,
      organizationId: payment.organizationId,
      userId: payment.booking.userId,
      amount: payment.amount,
    });

    if (result.transitionedBooking) {
      this.eventEmitter.emit(Events.BOOKING_CONFIRMED, {
        bookingId: payment.bookingId,
        organizationId: payment.organizationId,
        userId: payment.booking.userId,
        facilityName: 'facility',
        startTime: payment.booking.startTime,
      });
    }

    await this.auditService.record({
      organizationId: payment.organizationId,
      action: 'webhook:payment_captured_processed',
      resource: 'payment',
      resourceId: payment.id,
      status: 'success',
    });
  }

  private async processRefundEvent(
    event: any,
    providerOrderId: string,
    providerPaymentId: string,
    payload: any,
  ) {
    const payment = await this.prisma.payment.findFirst({
      where: {
        OR: [
          { providerPaymentId: payload.payment_id || payload.data?.object?.payment_intent },
          { providerOrderId },
        ],
      },
      include: { booking: true },
    });

    if (!payment) {
      await this.prisma.paymentWebhookEvent.update({
        where: { id: event.id },
        data: { status: WebhookStatus.FAILED, lastError: 'Payment record for refund not found' },
      });
      return;
    }

    if (payment.status === PaymentStatus.REFUNDED) {
      await this.prisma.paymentWebhookEvent.update({
        where: { id: event.id },
        data: {
          status: WebhookStatus.PROCESSED,
          paymentId: payment.id,
          organizationId: payment.organizationId,
          processedAt: new Date(),
        },
      });
      return;
    }

    // Update Payment status to REFUNDED
    await this.prisma.payment.update({
      where: { id: payment.id },
      data: { status: PaymentStatus.REFUNDED },
    });

    // Record Immutable Refund Ledger Reversal (Idempotent via refund_${payment.id}_${amount})
    await this.financeService.recordRefund({
      paymentId: payment.id,
      bookingId: payment.bookingId,
      organizationId: payment.organizationId,
      amount: payment.amount,
      reason: 'Webhook gateway refund notification',
      userId: payment.booking?.userId,
    });

    await this.prisma.paymentWebhookEvent.update({
      where: { id: event.id },
      data: {
        status: WebhookStatus.PROCESSED,
        paymentId: payment.id,
        organizationId: payment.organizationId,
        processedAt: new Date(),
      },
    });

    this.eventEmitter.emit(Events.PAYMENT_REFUNDED, {
      paymentId: payment.id,
      bookingId: payment.bookingId,
      organizationId: payment.organizationId,
      amount: payment.amount,
    });
  }

  // Admin Operational Methods
  async getWebhookLogs(filters: {
    provider?: string;
    status?: string;
    paymentId?: string;
    organizationId?: string;
    skip?: number;
    take?: number;
  }) {
    const where: any = {
      ...(filters.provider ? { provider: filters.provider.toUpperCase() } : {}),
      ...(filters.status ? { status: filters.status } : {}),
      ...(filters.paymentId ? { paymentId: filters.paymentId } : {}),
      ...(filters.organizationId ? { organizationId: filters.organizationId } : {}),
    };

    const [items, total] = await Promise.all([
      this.prisma.paymentWebhookEvent.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip: filters.skip,
        take: filters.take,
      }),
      this.prisma.paymentWebhookEvent.count({ where }),
    ]);

    return { items, total };
  }

  async getWebhookLogById(id: string) {
    const log = await this.prisma.paymentWebhookEvent.findUnique({
      where: { id },
    });
    if (!log) throw new NotFoundException('Webhook event log not found');
    return log;
  }

  async retryWebhookEvent(adminId: string, id: string) {
    const log = await this.getWebhookLogById(id);

    // Re-queue existing event
    await this.prisma.paymentWebhookEvent.update({
      where: { id },
      data: {
        status: WebhookStatus.QUEUED,
        lastError: null,
      },
    });

    await this.queueService.addWebhookJob(
      'process-webhook',
      { webhookEventId: id },
      { jobId: `${id}_retry_${Date.now()}` },
    );

    await this.auditService.record({
      userId: adminId,
      action: 'admin:webhook_retry_requested',
      resource: 'webhook_event',
      resourceId: id,
      status: 'success',
    });

    return { status: 'requeued', webhookEventId: id };
  }
}
