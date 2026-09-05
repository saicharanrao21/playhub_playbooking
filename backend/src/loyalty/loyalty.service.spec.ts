import { Test, TestingModule } from '@nestjs/testing';
import { LoyaltyService } from './loyalty.service';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../common/services/audit.service';
import { BadRequestException, ForbiddenException } from '@nestjs/common';

describe('LoyaltyService (Ledger & Referral Engine)', () => {
  let service: LoyaltyService;

  const mockPrisma = {
    loyaltyAccount: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    loyaltyTransaction: {
      findMany: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
      findUnique: jest.fn(),
    },
    referralCode: {
      findUnique: jest.fn(),
      create: jest.fn(),
    },
    referralCampaign: {
      findFirst: jest.fn(),
    },
    referral: {
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    $transaction: jest.fn((cb) => cb(mockPrisma)),
  };

  const mockAuditService = {
    record: jest.fn().mockResolvedValue({}),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        LoyaltyService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: AuditService, useValue: mockAuditService },
      ],
    }).compile();

    service = module.get<LoyaltyService>(LoyaltyService);
  });

  it('should block self-referral', async () => {
    mockPrisma.referralCode.findUnique.mockResolvedValue({
      id: 'ref-code-1',
      userId: 'user-101', // Same user
      code: 'PLAY-SELF',
    });

    await expect(
      service.applyReferralCode('user-101', 'PLAY-SELF'),
    ).rejects.toThrow(ForbiddenException);
  });

  it('should redeem loyalty points safely and deduct from balance', async () => {
    mockPrisma.loyaltyAccount.findUnique.mockResolvedValue({
      id: 'acc-101',
      userId: 'user-101',
      pointsBalance: 200,
    });

    mockPrisma.loyaltyTransaction.findUnique.mockResolvedValue(null);
    mockPrisma.loyaltyTransaction.create.mockResolvedValue({
      id: 'tx-101',
      points: -100,
      balanceAfter: 100,
    });

    const result = await service.redeemPoints('user-101', 100, 'BOOKING', 'book-101');
    expect(result.points).toBe(-100);
    expect(mockPrisma.loyaltyAccount.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ pointsBalance: 100 }),
      }),
    );
  });

  it('should reject point redemption if points balance is insufficient', async () => {
    mockPrisma.loyaltyAccount.findUnique.mockResolvedValue({
      id: 'acc-101',
      userId: 'user-101',
      pointsBalance: 50,
    });

    await expect(
      service.redeemPoints('user-101', 100, 'BOOKING', 'book-101'),
    ).rejects.toThrow(BadRequestException);
  });
});
