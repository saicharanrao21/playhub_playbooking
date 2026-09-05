import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCouponDto, CouponDiscountType } from './dto/create-coupon.dto';
import { ValidateCouponDto } from './dto/validate-coupon.dto';
import { Decimal } from '@prisma/client/runtime/library';

export interface CouponValidationResult {
  isValid: boolean;
  couponId: string;
  code: string;
  discountType: string;
  discountValue: number;
  discountAmount: number;
  finalAmount: number;
  message?: string;
}

@Injectable()
export class CouponsService {
  private readonly logger = new Logger(CouponsService.name);

  constructor(private readonly prisma: PrismaService) {}

  async createCoupon(dto: CreateCouponDto) {
    const code = dto.code.toUpperCase().trim();

    const existing = await this.prisma.coupon.findUnique({ where: { code } });
    if (existing) {
      throw new ConflictException(`Coupon code [${code}] already exists.`);
    }

    return this.prisma.coupon.create({
      data: {
        organizationId: dto.organizationId || null,
        code,
        description: dto.description,
        discountType: dto.discountType,
        discountValue: new Decimal(dto.discountValue),
        minBookingAmount: new Decimal(dto.minBookingAmount || 0),
        maxDiscountAmount: dto.maxDiscountAmount ? new Decimal(dto.maxDiscountAmount) : null,
        validFrom: dto.validFrom ? new Date(dto.validFrom) : null,
        validTo: dto.validTo ? new Date(dto.validTo) : null,
        totalRedemptionLimit: dto.totalRedemptionLimit || null,
        perUserRedemptionLimit: dto.perUserRedemptionLimit || 1,
        firstBookingOnly: dto.firstBookingOnly || false,
        membershipRequired: dto.membershipRequired || false,
        venueId: dto.venueId || null,
        facilityId: dto.facilityId || null,
        isActive: dto.isActive !== undefined ? dto.isActive : true,
      },
    });
  }

  async validateCoupon(userId: string, dto: ValidateCouponDto): Promise<CouponValidationResult> {
    const code = dto.code.toUpperCase().trim();
    const now = new Date();

    const coupon = await this.prisma.coupon.findUnique({
      where: { code },
    });

    if (!coupon || !coupon.isActive) {
      throw new BadRequestException('Invalid or inactive coupon code');
    }

    // 1. Date Range Validation
    if (coupon.validFrom && now < coupon.validFrom) {
      throw new BadRequestException('Coupon campaign has not started yet');
    }
    if (coupon.validTo && now > coupon.validTo) {
      throw new BadRequestException('Coupon code has expired');
    }

    // 2. Organization / Venue / Facility Scoping
    if (coupon.organizationId && dto.organizationId && coupon.organizationId !== dto.organizationId) {
      throw new BadRequestException('Coupon is not valid for this sports organization');
    }
    if (coupon.venueId && dto.venueId && coupon.venueId !== dto.venueId) {
      throw new BadRequestException('Coupon is not valid for this venue');
    }
    if (coupon.facilityId && dto.facilityId && coupon.facilityId !== dto.facilityId) {
      throw new BadRequestException('Coupon is not valid for this court facility');
    }

    // 3. Minimum Booking Amount
    const bookingAmt = dto.bookingAmount;
    const minAmt = Number(coupon.minBookingAmount);
    if (bookingAmt < minAmt) {
      throw new BadRequestException(`Booking amount (₹${bookingAmt}) is below minimum requirement of ₹${minAmt}`);
    }

    // 4. Total Redemption Limit
    if (coupon.totalRedemptionLimit !== null && coupon.totalRedemptionLimit !== undefined) {
      const totalRedeemed = await this.prisma.couponRedemption.count({
        where: { couponId: coupon.id, status: 'CONFIRMED' },
      });
      if (totalRedeemed >= coupon.totalRedemptionLimit) {
        throw new BadRequestException('Coupon total usage limit has been reached');
      }
    }

    // 5. Per-User Redemption Limit
    const userRedeemed = await this.prisma.couponRedemption.count({
      where: { couponId: coupon.id, userId, status: 'CONFIRMED' },
    });
    if (userRedeemed >= coupon.perUserRedemptionLimit) {
      throw new BadRequestException(`You have already used this coupon maximum allowed times (${coupon.perUserRedemptionLimit})`);
    }

    // 6. First Booking Only
    if (coupon.firstBookingOnly) {
      const userBookings = await this.prisma.booking.count({
        where: { userId, status: { in: ['CONFIRMED', 'CHECKED_IN', 'COMPLETED'] } },
      });
      if (userBookings > 0) {
        throw new BadRequestException('This coupon is valid for first-time bookings only');
      }
    }

    // 7. Membership Requirement
    if (coupon.membershipRequired) {
      const activeMembership = await this.prisma.customerMembership.findFirst({
        where: { userId, status: 'ACTIVE', expiryDate: { gte: now } },
      });
      if (!activeMembership) {
        throw new BadRequestException('This coupon requires an active PlayHub membership');
      }
    }

    // 8. Calculate Discount Amount
    let discountAmount = 0;
    const val = Number(coupon.discountValue);

    if (coupon.discountType === CouponDiscountType.PERCENTAGE) {
      discountAmount = Math.round((bookingAmt * (val / 100)) * 100) / 100;
      if (coupon.maxDiscountAmount) {
        discountAmount = Math.min(discountAmount, Number(coupon.maxDiscountAmount));
      }
    } else {
      discountAmount = val;
    }

    // Clamp discount to booking amount
    discountAmount = Math.min(discountAmount, bookingAmt);
    const finalAmount = Math.max(0, Math.round((bookingAmt - discountAmount) * 100) / 100);

    return {
      isValid: true,
      couponId: coupon.id,
      code: coupon.code,
      discountType: coupon.discountType,
      discountValue: val,
      discountAmount,
      finalAmount,
    };
  }

  async recordRedemption(
    tx: any,
    couponId: string,
    userId: string,
    bookingId: string,
    discountAmount: number,
    organizationId?: string,
  ) {
    const prismaClient = tx || this.prisma;
    return prismaClient.couponRedemption.create({
      data: {
        couponId,
        userId,
        bookingId,
        organizationId: organizationId || null,
        discountAmount: new Decimal(discountAmount),
        status: 'CONFIRMED',
      },
    });
  }

  async getCoupons(organizationId?: string) {
    return this.prisma.coupon.findMany({
      where: {
        isActive: true,
        OR: [
          ...(organizationId ? [{ organizationId }] : []),
          { organizationId: null },
        ],
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getCouponByCode(code: string) {
    return this.prisma.coupon.findUnique({
      where: { code: code.toUpperCase().trim() },
    });
  }
}
