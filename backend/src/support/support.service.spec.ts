import { Test, TestingModule } from '@nestjs/testing';
import { SupportService } from './support.service';
import { DisputesService } from './disputes.service';
import { PrismaService } from '../prisma/prisma.service';
import { PaymentsService } from '../payments/payments.service';
import { LoyaltyService } from '../loyalty/loyalty.service';
import { AuditService } from '../common/services/audit.service';
import { ForbiddenException, ConflictException } from '@nestjs/common';
import { TicketCategory, TicketPriority } from './dto/create-ticket.dto';
import { DisputeReason } from './dto/create-dispute.dto';
import { DisputeDecision } from './dto/resolve-dispute.dto';
import { Decimal } from '@prisma/client/runtime/library';

describe('SupportService & Dispute Resolution Engine', () => {
  let supportService: SupportService;
  let disputesService: DisputesService;

  const mockPrisma = {
    supportTicket: {
      create: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    supportMessage: {
      create: jest.fn(),
    },
    booking: {
      findFirst: jest.fn(),
    },
    dispute: {
      findFirst: jest.fn(),
      create: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
    },
    payment: {
      findFirst: jest.fn(),
    },
  };

  const mockPaymentsService = {
    initiateRefund: jest.fn().mockResolvedValue({ id: 'ref-101', status: 'REFUNDED' }),
  };

  const mockLoyaltyService = {
    earnPoints: jest.fn().mockResolvedValue({}),
  };

  const mockAuditService = {
    record: jest.fn().mockResolvedValue({}),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        SupportService,
        DisputesService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: PaymentsService, useValue: mockPaymentsService },
        { provide: LoyaltyService, useValue: mockLoyaltyService },
        { provide: AuditService, useValue: mockAuditService },
      ],
    }).compile();

    supportService = module.get<SupportService>(SupportService);
    disputesService = module.get<DisputesService>(DisputesService);
  });

  it('should create support ticket and initial customer message', async () => {
    mockPrisma.booking.findFirst.mockResolvedValue({ id: 'book-101', userId: 'user-101', organizationId: 'org-101' });
    mockPrisma.supportTicket.create.mockResolvedValue({
      id: 't-101',
      userId: 'user-101',
      subject: 'Court Lighting Issue',
      status: 'OPEN',
    });

    const ticket = await supportService.createTicket('user-101', {
      bookingId: 'book-101',
      category: TicketCategory.VENUE_ISSUE,
      subject: 'Court Lighting Issue',
      description: 'Floodlights went out during match.',
      priority: TicketPriority.HIGH,
    });

    expect(ticket.id).toBe('t-101');
    expect(mockPrisma.supportTicket.create).toHaveBeenCalled();
  });

  it('should throw ForbiddenException if user attempts to attach another user booking to ticket', async () => {
    mockPrisma.booking.findFirst.mockResolvedValue(null);

    await expect(
      supportService.createTicket('user-101', {
        bookingId: 'book-OTHER',
        category: TicketCategory.BOOKING_ISSUE,
        subject: 'Unauthorized',
        description: 'Detail',
      }),
    ).rejects.toThrow(ForbiddenException);
  });

  it('should create formal booking dispute and linked ticket', async () => {
    mockPrisma.booking.findFirst.mockResolvedValue({
      id: 'book-101',
      userId: 'user-101',
      organizationId: 'org-101',
      payments: [{ id: 'pay-101', status: 'CAPTURED' }],
    });
    mockPrisma.dispute.findFirst.mockResolvedValue(null);

    mockPrisma.supportTicket.create.mockResolvedValue({ id: 't-102' });
    mockPrisma.dispute.create.mockResolvedValue({
      id: 'disp-101',
      ticketId: 't-102',
      status: 'OPEN',
    });

    const dispute = await disputesService.createDispute('user-101', {
      bookingId: 'book-101',
      reason: DisputeReason.VENUE_CLOSED,
      description: 'Venue gates were locked upon arrival.',
    });

    expect(dispute.id).toBe('disp-101');
    expect(mockPrisma.dispute.create).toHaveBeenCalled();
  });

  it('should resolve dispute with FULL_REFUND and invoke PaymentsService refund', async () => {
    mockPrisma.dispute.findUnique.mockResolvedValue({
      id: 'disp-101',
      ticketId: 't-102',
      organizationId: 'org-101',
      customerId: 'user-101',
      status: 'OPEN',
      payment: { id: 'pay-101', status: 'CAPTURED', amount: new Decimal(1000) },
      booking: { payments: [{ id: 'pay-101', status: 'CAPTURED', amount: new Decimal(1000) }] },
    });

    mockPrisma.dispute.update.mockResolvedValue({ id: 'disp-101', status: 'DECIDED', decision: 'FULL_REFUND' });

    await disputesService.resolveDispute('admin-1', 'disp-101', {
      decision: DisputeDecision.FULL_REFUND,
      refundAmount: 1000,
      resolutionNotes: 'Venue confirmed closed. Full refund issued.',
    });

    expect(mockPaymentsService.initiateRefund).toHaveBeenCalledWith(
      'org-101',
      'pay-101',
      expect.stringContaining('Venue confirmed closed'),
    );
  });

  it('should resolve dispute with GOODWILL_CREDIT and award loyalty points', async () => {
    mockPrisma.dispute.findUnique.mockResolvedValue({
      id: 'disp-102',
      ticketId: 't-103',
      organizationId: 'org-101',
      customerId: 'user-101',
      status: 'OPEN',
      booking: { payments: [] },
    });

    mockPrisma.dispute.update.mockResolvedValue({ id: 'disp-102', status: 'DECIDED', decision: 'GOODWILL_CREDIT' });

    await disputesService.resolveDispute('admin-1', 'disp-102', {
      decision: DisputeDecision.GOODWILL_CREDIT,
      goodwillPoints: 200,
      resolutionNotes: 'Awarded 200 goodwill points for minor delay.',
    });

    expect(mockLoyaltyService.earnPoints).toHaveBeenCalledWith(
      'user-101',
      200,
      'DISPUTE_GOODWILL',
      'disp-102',
      'goodwill_dispute_disp-102',
    );
  });
});
