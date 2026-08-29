import { Test, TestingModule } from '@nestjs/testing';
import { FinanceService } from './finance.service';
import { PrismaService } from '../prisma/prisma.service';
import { FinancialTransactionType } from '@prisma/client';
import { Decimal } from '@prisma/client/runtime/library';

describe('FinanceService', () => {
  let service: FinanceService;
  let prisma: PrismaService;

  const mockPrisma = {
    financialTransaction: {
      findUnique: jest.fn(),
      create: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
    },
    ledgerEntry: {
      create: jest.fn(),
      aggregate: jest.fn(),
    },
    commissionConfig: {
      findFirst: jest.fn(),
    },
    $transaction: jest.fn((cb) => cb(mockPrisma)),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FinanceService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<FinanceService>(FinanceService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should record a payment and create ledger entries', async () => {
    mockPrisma.financialTransaction.findUnique.mockResolvedValue(null);
    mockPrisma.commissionConfig.findFirst.mockResolvedValue({ percentage: new Decimal(10) });
    mockPrisma.financialTransaction.create.mockResolvedValue({ id: 'tx-1' });

    await service.recordPayment({
      paymentId: 'pay-1',
      bookingId: 'book-1',
      organizationId: 'org-1',
      amount: 1000,
    });

    expect(mockPrisma.financialTransaction.create).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({
        amount: new Decimal(1000),
        type: FinancialTransactionType.PAYMENT,
      }),
    }));

    // Should create 3 ledger entries: clearing, payable, revenue
    expect(mockPrisma.ledgerEntry.create).toHaveBeenCalledTimes(3);
  });

  it('should calculate partner balance correctly', async () => {
    mockPrisma.ledgerEntry.aggregate.mockResolvedValue({
      _sum: {
        credit: new Decimal(5000),
        debit: new Decimal(2000),
      },
    });

    const result = await service.getPartnerBalance('org-1');
    expect(result.availableBalance).toBe(3000);
  });
});
