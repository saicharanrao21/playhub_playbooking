import { Test, TestingModule } from '@nestjs/testing';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { PaymentsService } from './payments.service';
import { PrismaService } from '../prisma/prisma.service';
import { PAYMENT_PROVIDER } from './interfaces/payment-provider.interface';
import { PaymentProviderFactory } from './providers/payment-provider.factory';
import { BookingStatus, PaymentStatus } from '@prisma/client';
import { BadRequestException, ConflictException } from '@nestjs/common';

describe('PaymentsService', () => {
  let service: PaymentsService;
  let prisma: PrismaService;

  const mockPrisma = {
    booking: { findFirst: jest.fn(), update: jest.fn().mockReturnValue(Promise.resolve({})) },
    payment: { create: jest.fn(), findUnique: jest.fn(), findFirst: jest.fn(), update: jest.fn().mockReturnValue(Promise.resolve({})) },
    paymentWebhookEvent: { findUnique: jest.fn(), create: jest.fn().mockReturnValue(Promise.resolve({})) },
    auditLog: { create: jest.fn() },
    $transaction: jest.fn((cb) => cb(mockPrisma)),
  };

  const mockProvider = {
    createOrder: jest.fn(),
    verifyWebhookSignature: jest.fn(),
    verifyCheckout: jest.fn(),
    initiateRefund: jest.fn(),
    getOrderStatus: jest.fn(),
  };

  const mockFactory = {
    getProvider: jest.fn().mockReturnValue(mockProvider),
  };

  const mockEventEmitter = {
    emit: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PaymentsService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: PaymentProviderFactory, useValue: mockFactory },
        { provide: PAYMENT_PROVIDER, useValue: mockProvider },
        { provide: EventEmitter2, useValue: mockEventEmitter },
      ],
    }).compile();

    service = module.get<PaymentsService>(PaymentsService);
    prisma = module.get<PrismaService>(PrismaService);

    jest.clearAllMocks();
  });

  it('should throw BadRequestException for cancelled bookings', async () => {
    mockPrisma.booking.findFirst.mockResolvedValue({ id: 'b1', userId: 'u1', status: BookingStatus.CANCELLED, payments: [] });
    await expect(service.createOrder('org1', 'u1', { bookingId: 'b1' }))
      .rejects.toThrow(BadRequestException);
  });

  it('should create order with server-calculated amount', async () => {
    mockPrisma.booking.findFirst.mockResolvedValue({
      id: 'b1',
      userId: 'u1',
      status: BookingStatus.PENDING,
      totalPrice: 100.50,
      currency: 'INR',
      payments: []
    });
    mockProvider.createOrder.mockResolvedValue({ id: 'order_123', amount: 10050 });
    mockPrisma.payment.create.mockResolvedValue({ id: 'p1' });

    await service.createOrder('org1', 'u1', { bookingId: 'b1' });

    expect(mockProvider.createOrder).toHaveBeenCalledWith(expect.objectContaining({
      amount: 10050 // minor units
    }));
  });

  it('should process webhook capture successfully with idempotency', async () => {
    const payload = { id: 'evt_123', event: 'payment.captured', order_id: 'order_123' };
    const signature = 'valid_sig';

    mockProvider.verifyWebhookSignature.mockReturnValue(true);
    mockPrisma.paymentWebhookEvent.findUnique.mockResolvedValue(null);
    mockPrisma.payment.findFirst.mockResolvedValue({
      id: 'p1',
      organizationId: 'org1',
      bookingId: 'b1',
      status: PaymentStatus.INITIATED,
      booking: { userId: 'u1' }
    });
    mockPrisma.payment.update.mockResolvedValue({ id: 'p1', status: PaymentStatus.CAPTURED });

    const result = await service.handleWebhook('RAZORPAY', payload, signature);

    expect(result).toEqual({ status: 'success' });
    expect(mockPrisma.paymentWebhookEvent.create).toHaveBeenCalledWith(expect.objectContaining({
        data: expect.objectContaining({ providerEventId: 'evt_123' })
    }));
  });

  it('should ignore duplicate webhooks', async () => {
    mockPrisma.paymentWebhookEvent.findUnique.mockResolvedValue({ id: 'processed' });
    const result = await service.handleWebhook('RAZORPAY', { id: 'evt_123' }, 'sig');
    expect(result.status).toBe('ignored');
  });

  it('should be idempotent in createOrder by reusing pending payments', async () => {
    const pendingPayment = { id: 'p1', provider: 'RAZORPAY', status: PaymentStatus.INITIATED };
    mockPrisma.booking.findFirst.mockResolvedValue({
        id: 'b1',
        userId: 'u1',
        organizationId: 'org1',
        payments: [pendingPayment]
    });

    const result = await service.createOrder('org1', 'u1', { bookingId: 'b1', provider: 'RAZORPAY' as any });
    expect(result).toEqual(pendingPayment);
    expect(mockProvider.createOrder).not.toHaveBeenCalled();
  });
});
