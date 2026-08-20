import { Test, TestingModule } from '@nestjs/testing';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { PaymentsService } from './payments.service';
import { PrismaService } from '../prisma/prisma.service';
import { IPaymentProvider, PAYMENT_PROVIDER } from './interfaces/payment-provider.interface';
import { PaymentProviderFactory } from './providers/payment-provider.factory';
import { BookingStatus, PaymentStatus, PaymentProvider } from '@prisma/client';
import { BadRequestException, ConflictException } from '@nestjs/common';

describe('PaymentsService', () => {
  let service: PaymentsService;
  let prisma: PrismaService;
  let factory: PaymentProviderFactory;

  const mockPrisma = {
    booking: { findFirst: jest.fn(), update: jest.fn().mockReturnValue(Promise.resolve({})) },
    payment: { create: jest.fn(), findUnique: jest.fn(), update: jest.fn().mockReturnValue(Promise.resolve({})) },
    auditLog: { create: jest.fn() },
    $transaction: jest.fn((cb) => cb(mockPrisma)),
  };

  const mockProvider = {
    createOrder: jest.fn(),
    verifySignature: jest.fn(),
    verifyCheckout: jest.fn(),
    initiateRefund: jest.fn(),
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
    factory = module.get<PaymentProviderFactory>(PaymentProviderFactory);

    jest.clearAllMocks();
  });

  it('should throw BadRequestException for cancelled bookings', async () => {
    mockPrisma.booking.findFirst.mockResolvedValue({ id: 'b1', userId: 'u1', status: BookingStatus.CANCELLED, payments: [] });
    await expect(service.createOrder('org1', 'u1', { bookingId: 'b1' }))
      .rejects.toThrow(BadRequestException);
  });

  it('should throw ConflictException if already paid', async () => {
    mockPrisma.booking.findFirst.mockResolvedValue({
      id: 'b1',
      userId: 'u1',
      status: BookingStatus.PENDING,
      payments: [{ status: PaymentStatus.CAPTURED }]
    });
    await expect(service.createOrder('org1', 'u1', { bookingId: 'b1' }))
      .rejects.toThrow(ConflictException);
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

  it('should use verifyCheckout if available during verifyPayment', async () => {
    const dto = {
      providerOrderId: 'order_123',
      providerPaymentId: 'pay_abc',
      signature: 'valid_sig'
    };

    mockPrisma.payment.findUnique.mockResolvedValue({
      id: 'p1',
      organizationId: 'org1',
      bookingId: 'b1',
      amount: 100.50,
      status: PaymentStatus.INITIATED,
      booking: { userId: 'u1' }
    });

    mockProvider.verifyCheckout.mockResolvedValue(true);

    await service.verifyPayment('org1', 'u1', dto);

    expect(mockProvider.verifyCheckout).toHaveBeenCalledWith(dto, 10050);
  });

  it('should process webhook capture successfully', async () => {
    const payload = { event: 'payment.captured', order_id: 'order_123', payment_id: 'pay_abc' };
    const signature = 'valid_sig';

    mockProvider.verifySignature.mockReturnValue(true);
    mockPrisma.payment.findUnique.mockResolvedValue({
      id: 'p1',
      organizationId: 'org1',
      bookingId: 'b1',
      status: PaymentStatus.INITIATED,
      booking: { userId: 'u1' }
    });
    mockPrisma.payment.update.mockResolvedValue({ id: 'p1', status: PaymentStatus.CAPTURED });

    const result = await service.handleWebhook('RAZORPAY', payload, signature);

    expect(result).toEqual({ status: 'success' });
    expect(mockPrisma.payment.update).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'p1' }
    }));
  });

  it('should ignore duplicate webhooks', async () => {
    const payload = { event: 'payment.captured', order_id: 'order_123' };
    mockProvider.verifySignature.mockReturnValue(true);
    mockPrisma.payment.findUnique.mockResolvedValue({
      id: 'p1',
      status: PaymentStatus.CAPTURED,
    });

    const result = await service.handleWebhook('RAZORPAY', payload, 'valid_sig');

    expect(result.status).toBe('noop');
  });

  it('should throw BadRequestException for invalid state transitions in verifyPayment', async () => {
    mockPrisma.payment.findUnique.mockResolvedValue({
      id: 'p1',
      organizationId: 'org1',
      status: PaymentStatus.FAILED,
      booking: { userId: 'u1' }
    });

    await expect(service.verifyPayment('org1', 'u1', {
      providerOrderId: 'order_123',
      providerPaymentId: 'pay_abc',
      signature: 'valid_sig'
    })).rejects.toThrow(BadRequestException);
  });

  it('should be idempotent in createOrder if idempotencyKey is provided', async () => {
    const existingPayment = { id: 'p1', bookingId: 'b1', organizationId: 'org1' };
    mockPrisma.booking.findFirst.mockResolvedValue({ id: 'b1', userId: 'u1', organizationId: 'org1', payments: [] });
    mockPrisma.payment.findUnique.mockResolvedValue(existingPayment);

    const result = await service.createOrder('org1', 'u1', { bookingId: 'b1' }, 'key_123');
    expect(result).toEqual(existingPayment);
    expect(mockProvider.createOrder).not.toHaveBeenCalled();
  });
});
