import { Test, TestingModule } from '@nestjs/testing';
import { WebhooksService } from './webhooks.service';
import { PrismaService } from '../prisma/prisma.service';
import { PaymentProviderFactory } from '../payments/providers/payment-provider.factory';
import { FinanceService } from '../finance/finance.service';
import { QueueService } from '../queues/queue.service';
import { AuditService } from '../common/services/audit.service';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { BadRequestException } from '@nestjs/common';
import { PaymentStatus, BookingStatus, PaymentProvider, Prisma } from '@prisma/client';
import { WebhookStatus } from './webhooks.types';
import { Decimal } from '@prisma/client/runtime/library';

describe('WebhooksService & Gateway Resilience', () => {
  let service: WebhooksService;

  const mockPrisma = {
    paymentWebhookEvent: {
      create: jest.fn(),
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
      update: jest.fn(),
    },
    payment: {
      findFirst: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    booking: {
      update: jest.fn(),
    },
    $transaction: jest.fn((cb) => cb(mockPrisma)),
  };

  const mockProvider = {
    verifyWebhookSignature: jest.fn(),
  };

  const mockProviderFactory = {
    getProvider: jest.fn().mockReturnValue(mockProvider),
  };

  const mockFinanceService = {
    recordPayment: jest.fn().mockResolvedValue({}),
    recordRefund: jest.fn().mockResolvedValue({}),
  };

  const mockQueueService = {
    addWebhookJob: jest.fn().mockResolvedValue({ id: 'job_101' }),
  };

  const mockAuditService = {
    record: jest.fn().mockResolvedValue({}),
  };

  const mockEventEmitter = {
    emit: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WebhooksService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: PaymentProviderFactory, useValue: mockProviderFactory },
        { provide: FinanceService, useValue: mockFinanceService },
        { provide: QueueService, useValue: mockQueueService },
        { provide: AuditService, useValue: mockAuditService },
        { provide: EventEmitter2, useValue: mockEventEmitter },
      ],
    }).compile();

    service = module.get<WebhooksService>(WebhooksService);
  });

  it('should verify valid Razorpay webhook signature and enqueue job', async () => {
    mockProvider.verifyWebhookSignature.mockReturnValue(true);
    mockPrisma.paymentWebhookEvent.create.mockResolvedValue({
      id: 'wh-101',
      provider: 'RAZORPAY',
      providerEventId: 'evt_rzp_1',
      status: WebhookStatus.QUEUED,
    });

    const payload = { id: 'evt_rzp_1', event: 'payment.captured', payload: {} };
    const res = await service.receiveWebhook('RAZORPAY', payload, 'valid_signature', 'raw_body');

    expect(res.received).toBe(true);
    expect(res.status).toBe('queued');
    expect(mockQueueService.addWebhookJob).toHaveBeenCalledWith('process-webhook', { webhookEventId: 'wh-101' }, { jobId: 'wh-101' });
  });

  it('should throw BadRequestException on invalid webhook signature', async () => {
    mockProvider.verifyWebhookSignature.mockReturnValue(false);

    await expect(
      service.receiveWebhook('RAZORPAY', { id: 'evt_rzp_1' }, 'bad_sig', 'raw_body'),
    ).rejects.toThrow(BadRequestException);
  });

  it('should gracefully handle duplicate webhook events idempotently', async () => {
    mockProvider.verifyWebhookSignature.mockReturnValue(true);
    const p2002Error = new Prisma.PrismaClientKnownRequestError('Unique constraint failed', {
      code: 'P2002',
      clientVersion: '5.22.0',
    });
    mockPrisma.paymentWebhookEvent.create.mockRejectedValue(p2002Error);

    const res = await service.receiveWebhook('RAZORPAY', { id: 'evt_dup_1' }, 'valid_sig', 'raw');

    expect(res.received).toBe(true);
    expect(res.status).toBe('ignored');
    expect(res.reason).toContain('Duplicate webhook event');
  });

  it('should process payment.captured event, update payment/booking status, and record finance ledger', async () => {
    const mockEvent = {
      id: 'wh-101',
      provider: 'RAZORPAY',
      eventType: 'payment.captured',
      payload: { id: 'evt_1', event: 'payment.captured', payment_id: 'pay_rzp_1', order_id: 'order_rzp_1' },
      status: 'QUEUED',
    };

    mockPrisma.paymentWebhookEvent.findUnique.mockResolvedValue(mockEvent);
    mockPrisma.paymentWebhookEvent.update.mockResolvedValue({});

    const mockPayment = {
      id: 'pay-1',
      bookingId: 'book-1',
      organizationId: 'org-1',
      amount: new Decimal(1000),
      status: PaymentStatus.INITIATED,
      booking: { id: 'book-1', userId: 'user-1', startTime: new Date() },
    };

    mockPrisma.payment.findFirst.mockResolvedValue(mockPayment);
    mockPrisma.payment.findUnique.mockResolvedValue(mockPayment);
    mockPrisma.payment.update.mockResolvedValue({ ...mockPayment, status: PaymentStatus.CAPTURED });
    mockPrisma.booking.update.mockResolvedValue({ id: 'book-1', status: BookingStatus.CONFIRMED });

    await service.processWebhookEvent('wh-101');

    expect(mockFinanceService.recordPayment).toHaveBeenCalledWith(
      expect.objectContaining({
        paymentId: 'pay-1',
        bookingId: 'book-1',
        amount: new Decimal(1000),
      }),
    );
    expect(mockEventEmitter.emit).toHaveBeenCalledWith('payment.captured', expect.any(Object));
  });

  it('should process refund.processed event and record refund ledger reversal', async () => {
    const mockEvent = {
      id: 'wh-102',
      provider: 'RAZORPAY',
      eventType: 'refund.processed',
      payload: { id: 'evt_ref_1', event: 'refund.processed', payment_id: 'pay_rzp_1' },
      status: 'QUEUED',
    };

    mockPrisma.paymentWebhookEvent.findUnique.mockResolvedValue(mockEvent);
    mockPrisma.paymentWebhookEvent.update.mockResolvedValue({});

    const mockPayment = {
      id: 'pay-1',
      bookingId: 'book-1',
      organizationId: 'org-1',
      amount: new Decimal(1000),
      status: PaymentStatus.CAPTURED,
      booking: { id: 'book-1', userId: 'user-1' },
    };

    mockPrisma.payment.findFirst.mockResolvedValue(mockPayment);
    mockPrisma.payment.update.mockResolvedValue({ ...mockPayment, status: PaymentStatus.REFUNDED });

    await service.processWebhookEvent('wh-102');

    expect(mockFinanceService.recordRefund).toHaveBeenCalledWith(
      expect.objectContaining({
        paymentId: 'pay-1',
        bookingId: 'book-1',
        amount: new Decimal(1000),
      }),
    );
  });
});
