import { Test, TestingModule } from '@nestjs/testing';
import { PaymentsService } from './payments.service';
import { PrismaService } from '../prisma/prisma.service';
import { IPaymentProvider, PAYMENT_PROVIDER } from './interfaces/payment-provider.interface';
import { BookingStatus, PaymentStatus } from '@prisma/client';
import { BadRequestException, ConflictException } from '@nestjs/common';

describe('PaymentsService', () => {
  let service: PaymentsService;
  let prisma: PrismaService;
  let provider: IPaymentProvider;

  const mockPrisma = {
    booking: { findFirst: jest.fn(), update: jest.fn() },
    payment: { create: jest.fn(), findUnique: jest.fn(), update: jest.fn() },
    auditLog: { create: jest.fn() },
    $transaction: jest.fn((cb) => cb(mockPrisma)),
  };

  const mockProvider = {
    createOrder: jest.fn(),
    verifySignature: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PaymentsService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: PAYMENT_PROVIDER, useValue: mockProvider },
      ],
    }).compile();

    service = module.get<PaymentsService>(PaymentsService);
    prisma = module.get<PrismaService>(PrismaService);
    provider = module.get<IPaymentProvider>(PAYMENT_PROVIDER);
  });

  it('should throw BadRequestException for cancelled bookings', async () => {
    mockPrisma.booking.findFirst.mockResolvedValue({ id: 'b1', status: BookingStatus.CANCELLED, payments: [] });
    await expect(service.createOrder('org1', 'u1', { bookingId: 'b1' }))
      .rejects.toThrow(BadRequestException);
  });

  it('should throw ConflictException if already paid', async () => {
    mockPrisma.booking.findFirst.mockResolvedValue({
      id: 'b1',
      status: BookingStatus.PENDING,
      payments: [{ status: PaymentStatus.CAPTURED }]
    });
    await expect(service.createOrder('org1', 'u1', { bookingId: 'b1' }))
      .rejects.toThrow(ConflictException);
  });

  it('should create order with server-calculated amount', async () => {
    mockPrisma.booking.findFirst.mockResolvedValue({
      id: 'b1',
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
      where: expect.objectContaining({ status: { not: PaymentStatus.CAPTURED } })
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
});
