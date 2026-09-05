import { Test, TestingModule } from '@nestjs/testing';
import { CouponsService } from './coupons.service';
import { PrismaService } from '../prisma/prisma.service';
import { BadRequestException, ConflictException } from '@nestjs/common';
import { CouponDiscountType } from './dto/create-coupon.dto';
import { Decimal } from '@prisma/client/runtime/library';

describe('CouponsService (Promotions & Coupon Validation Engine)', () => {
  let service: CouponsService;

  const mockPrisma = {
    coupon: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
    },
    couponRedemption: {
      count: jest.fn(),
      create: jest.fn(),
    },
    booking: {
      count: jest.fn(),
    },
    customerMembership: {
      findFirst: jest.fn(),
    },
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CouponsService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<CouponsService>(CouponsService);
  });

  it('should validate percentage coupon and calculate correct discount', async () => {
    mockPrisma.coupon.findUnique.mockResolvedValue({
      id: 'cpn-101',
      code: 'PLAYHUB10',
      isActive: true,
      discountType: CouponDiscountType.PERCENTAGE,
      discountValue: new Decimal(10),
      minBookingAmount: new Decimal(500),
      maxDiscountAmount: new Decimal(100),
      perUserRedemptionLimit: 2,
    });

    mockPrisma.couponRedemption.count.mockResolvedValue(0);

    const result = await service.validateCoupon('user-101', {
      code: 'PLAYHUB10',
      bookingAmount: 800,
    });

    expect(result.isValid).toBe(true);
    expect(result.discountAmount).toBe(80); // 10% of 800
    expect(result.finalAmount).toBe(720);
  });

  it('should reject coupon if booking amount is below minimum requirement', async () => {
    mockPrisma.coupon.findUnique.mockResolvedValue({
      id: 'cpn-101',
      code: 'MIN500',
      isActive: true,
      minBookingAmount: new Decimal(500),
      discountType: CouponDiscountType.FIXED,
      discountValue: new Decimal(100),
      perUserRedemptionLimit: 1,
    });

    await expect(
      service.validateCoupon('user-101', { code: 'MIN500', bookingAmount: 300 }),
    ).rejects.toThrow(BadRequestException);
  });

  it('should reject coupon if user per-user redemption limit reached', async () => {
    mockPrisma.coupon.findUnique.mockResolvedValue({
      id: 'cpn-101',
      code: 'ONCE100',
      isActive: true,
      minBookingAmount: new Decimal(0),
      perUserRedemptionLimit: 1,
      discountType: CouponDiscountType.FIXED,
      discountValue: new Decimal(100),
    });

    mockPrisma.couponRedemption.count.mockResolvedValue(1);

    await expect(
      service.validateCoupon('user-101', { code: 'ONCE100', bookingAmount: 1000 }),
    ).rejects.toThrow(BadRequestException);
  });
});
