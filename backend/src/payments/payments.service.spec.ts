import { Test, TestingModule } from '@nestjs/testing';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { PaymentsService } from './payments.service';
import { PrismaService } from '../prisma/prisma.service';
import { PAYMENT_PROVIDER } from './interfaces/payment-provider.interface';
import { PaymentProviderFactory } from './providers/payment-provider.factory';
import { BookingStatus, PaymentStatus } from '@prisma/client';
import { BadRequestException, ConflictException, ForbiddenException, NotFoundException } from '@nestjs/common';

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

  describe('createOrder', () => {
    it('should throw BadRequestException for cancelled bookings', async () => {
      mockPrisma.booking.findFirst.mockResolvedValue({ id: 'b1', userId: 'u1', status: BookingStatus.CANCELLED, payments: [] });
      await expect(service.createOrder('org1', 'u1', { bookingId: 'b1' }))
        .rejects.toThrow(BadRequestException);
    });

    it('should throw ForbiddenException if user does not own the booking', async () => {
      mockPrisma.booking.findFirst.mockResolvedValue({ id: 'b1', userId: 'other', status: BookingStatus.PENDING, payments: [] });
      await expect(service.createOrder('org1', 'u1', { bookingId: 'b1' }))
        .rejects.toThrow(ForbiddenException);
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
  });

  describe('handleWebhook', () => {
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
      mockPrisma.payment.findUnique.mockResolvedValue({
        id: 'p1',
        status: PaymentStatus.INITIATED,
      });
      mockPrisma.payment.update.mockResolvedValue({ id: 'p1', status: PaymentStatus.CAPTURED });

      const result = await service.handleWebhook('RAZORPAY', payload, signature);

      expect(result).toEqual({ status: 'success' });
      expect(mockPrisma.paymentWebhookEvent.create).toHaveBeenCalledWith(expect.objectContaining({
          data: expect.objectContaining({ providerEventId: 'evt_123' })
      }));
    });

    it('should throw BadRequestException for invalid signature', async () => {
      mockProvider.verifyWebhookSignature.mockReturnValue(false);
      await expect(service.handleWebhook('RAZORPAY', {}, 'invalid'))
        .rejects.toThrow(BadRequestException);
    });

    it('should ignore duplicate webhooks', async () => {
      mockProvider.verifyWebhookSignature.mockReturnValue(true);
      mockPrisma.paymentWebhookEvent.findUnique.mockResolvedValue({ id: 'processed' });
      const result = await service.handleWebhook('RAZORPAY', { id: 'evt_123' }, 'valid_sig');
      expect(result.status).toBe('ignored');
    });
  });

  describe('reconcilePayment', () => {
    it('should reconcile successful payment from provider status', async () => {
      mockPrisma.payment.findUnique.mockResolvedValue({
          id: 'p1',
          organizationId: 'org1',
          status: PaymentStatus.INITIATED,
          provider: 'RAZORPAY',
          providerOrderId: 'order_123',
          bookingId: 'b1'
      });
      mockProvider.getOrderStatus.mockResolvedValue('paid');
      mockPrisma.payment.update.mockResolvedValue({ id: 'p1', status: PaymentStatus.CAPTURED });

      const result = await service.reconcilePayment('org1', 'p1');
      expect(result.status).toBe(PaymentStatus.CAPTURED);
    });

    it('should throw NotFoundException if payment belongs to different organization', async () => {
      mockPrisma.payment.findUnique.mockResolvedValue(null);
      await expect(service.reconcilePayment('wrong-org', 'p1')).rejects.toThrow(NotFoundException);
    });
  });
});
