import { Test, TestingModule } from '@nestjs/testing';
import { FinanceService } from './finance.service';
import { ReconciliationService } from './reconciliation.service';
import { PayoutService } from './payout.service';
import { SettlementService } from './settlement.service';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../common/services/audit.service';
import { FinancialTransactionType, PaymentStatus, KYCStatus, PayoutStatus } from '@prisma/client';
import { Decimal } from '@prisma/client/runtime/library';

describe('Finance & Governance Engine', () => {
  let financeService: FinanceService;
  let reconciliationService: ReconciliationService;
  let payoutService: PayoutService;
  let prisma: PrismaService;

  const mockPrisma = {
    financialTransaction: {
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      count: jest.fn(),
      updateMany: jest.fn(),
    },
    ledgerEntry: {
      create: jest.fn(),
      aggregate: jest.fn(),
    },
    commissionConfig: {
      findMany: jest.fn(),
      findFirst: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    payment: {
      findUnique: jest.fn(),
      findFirst: jest.fn(),
      findMany: jest.fn(),
    },
    organization: {
      findUnique: jest.fn(),
    },
    settlement: {
      create: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
    },
    payout: {
      create: jest.fn(),
      findUnique: jest.fn(),
      findMany: jest.fn(),
      update: jest.fn(),
      aggregate: jest.fn(),
    },
    auditLog: {
      create: jest.fn(),
    },
    $transaction: jest.fn((cb) => cb(mockPrisma)),
  };

  const mockAuditService = {
    record: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FinanceService,
        ReconciliationService,
        PayoutService,
        SettlementService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: AuditService, useValue: mockAuditService },
      ],
    }).compile();

    financeService = module.get<FinanceService>(FinanceService);
    reconciliationService = module.get<ReconciliationService>(ReconciliationService);
    payoutService = module.get<PayoutService>(PayoutService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should record payment with 10% commission and double-entry balance', async () => {
    mockPrisma.financialTransaction.findUnique.mockResolvedValue(null);
    mockPrisma.commissionConfig.findMany.mockResolvedValue([
      { percentage: new Decimal(10), fixedFee: new Decimal(0) },
    ]);
    mockPrisma.financialTransaction.create.mockResolvedValue({ id: 'tx-101' });

    await financeService.recordPayment({
      paymentId: 'pay-101',
      bookingId: 'book-101',
      organizationId: 'org-101',
      amount: 1000,
    });

    expect(mockPrisma.financialTransaction.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          amount: new Decimal(1000),
          type: FinancialTransactionType.PAYMENT,
        }),
      }),
    );

    // 3 ledger entries: PAYMENT_CLEARING (Dr 1000), PARTNER_PAYABLE (Cr 900), PLATFORM_REVENUE (Cr 100)
    expect(mockPrisma.ledgerEntry.create).toHaveBeenCalledTimes(3);
  });

  it('should record refund and reverse commission and partner payable proportionally', async () => {
    mockPrisma.payment.findUnique.mockResolvedValue({
      id: 'pay-101',
      amount: new Decimal(1000),
      booking: { userId: 'user-1' },
      financialTransactions: [
        {
          id: 'tx-101',
          type: FinancialTransactionType.PAYMENT,
          amount: new Decimal(1000),
          metadata: { commissionPercentage: 10.0 },
        },
      ],
    });

    mockPrisma.financialTransaction.create.mockResolvedValue({ id: 'tx-refund-101' });

    await financeService.recordRefund({
      paymentId: 'pay-101',
      bookingId: 'book-101',
      organizationId: 'org-101',
      amount: 1000,
      reason: 'Customer cancelled',
    });

    expect(mockPrisma.financialTransaction.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          type: FinancialTransactionType.REFUND,
          amount: new Decimal(1000),
        }),
      }),
    );

    // 3 reversal ledger entries created
    expect(mockPrisma.ledgerEntry.create).toHaveBeenCalledTimes(3);
  });

  it('should run reconciliation and detect no discrepancies on clean state', async () => {
    mockPrisma.payment.findMany.mockResolvedValue([]);
    mockPrisma.financialTransaction.findMany.mockResolvedValue([]);
    mockPrisma.payout.findMany.mockResolvedValue([]);
    mockPrisma.ledgerEntry.aggregate.mockResolvedValue({ _sum: { credit: new Decimal(0), debit: new Decimal(0) } });

    const report = await reconciliationService.runReconciliation({});
    expect(report.reconciliationStatus).toBe('HEALTHY');
    expect(report.discrepancyCount).toBe(0);
  });

  it('should prevent payout if KYC is not APPROVED', async () => {
    mockPrisma.organization.findUnique.mockResolvedValue({
      id: 'org-101',
      kycStatus: KYCStatus.UNDER_REVIEW,
      accountNumber: '1234567890',
      ifscCode: 'HDFC0001234',
      accountHolderName: 'Test Sports Ltd',
    });

    await expect(
      payoutService.initiatePayout('org-101', { amount: 500 }),
    ).rejects.toThrow('Payouts require APPROVED KYC status');
  });
});
