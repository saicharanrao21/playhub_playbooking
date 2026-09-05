import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
  ConflictException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../common/services/audit.service';
import { Prisma } from '@prisma/client';
import * as crypto from 'crypto';

@Injectable()
export class LoyaltyService {
  private readonly logger = new Logger(LoyaltyService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AuditService,
  ) {}

  /**
   * Finds or initializes user's LoyaltyAccount.
   */
  async getOrCreateAccount(userId: string) {
    const existing = await this.prisma.loyaltyAccount.findUnique({
      where: { userId },
    });

    if (existing) return existing;

    return this.prisma.loyaltyAccount.create({
      data: {
        userId,
        pointsBalance: 0,
        lifetimeEarned: 0,
      },
    });
  }

  async getAccount(userId: string) {
    return this.getOrCreateAccount(userId);
  }

  async getTransactions(userId: string, skip = 0, take = 20) {
    const [items, total] = await Promise.all([
      this.prisma.loyaltyTransaction.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        skip,
        take,
      }),
      this.prisma.loyaltyTransaction.count({ where: { userId } }),
    ]);

    return { items, total };
  }

  /**
   * Generates or retrieves unique referral code for user.
   */
  async getOrCreateReferralCode(userId: string) {
    const existing = await this.prisma.referralCode.findUnique({
      where: { userId },
    });

    if (existing) return existing;

    // Generate readable code e.g. PLAY-8F91
    const randHex = crypto.randomBytes(2).toString('hex').toUpperCase();
    const code = `PLAY-${randHex}`;

    try {
      return await this.prisma.referralCode.create({
        data: {
          userId,
          code,
        },
      });
    } catch (e) {
      if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
        const fallbackCode = `PLAY-${crypto.randomBytes(3).toString('hex').toUpperCase()}`;
        return this.prisma.referralCode.create({
          data: { userId, code: fallbackCode },
        });
      }
      throw e;
    }
  }

  /**
   * Applies a referral code when a referee registers or enters code.
   * Blocks self-referral and duplicate referrals.
   */
  async applyReferralCode(refereeId: string, code: string) {
    const cleanCode = code.toUpperCase().trim();

    const referralCode = await this.prisma.referralCode.findUnique({
      where: { code: cleanCode },
    });

    if (!referralCode) {
      throw new BadRequestException('Invalid referral code');
    }

    if (referralCode.userId === refereeId) {
      throw new ForbiddenException('Self-referral is not allowed');
    }

    const existingRef = await this.prisma.referral.findUnique({
      where: { refereeId },
    });

    if (existingRef) {
      throw new ConflictException('You have already applied a referral code');
    }

    // Find active campaign
    const campaign = await this.prisma.referralCampaign.findFirst({
      where: { isActive: true },
      orderBy: { createdAt: 'desc' },
    });

    return this.prisma.referral.create({
      data: {
        campaignId: campaign?.id || null,
        referrerId: referralCode.userId,
        refereeId,
        status: 'PENDING',
      },
    });
  }

  /**
   * Qualifies referral upon referee completing first valid booking.
   * Atomically issues rewards to referrer and referee.
   */
  async qualifyReferral(refereeId: string, bookingId: string, bookingAmount: number) {
    const referral = await this.prisma.referral.findUnique({
      where: { refereeId },
      include: { campaign: true },
    });

    if (!referral || referral.status !== 'PENDING') return null;

    const campaign = referral.campaign;
    const minAmt = campaign ? Number(campaign.minQualifyingAmount) : 0;

    if (bookingAmount < minAmt) return null;

    // Qualify referral & issue points idempotently
    return this.prisma.$transaction(async (tx) => {
      const updatedRef = await tx.referral.update({
        where: { id: referral.id },
        data: {
          status: 'QUALIFIED',
          qualifyingBookingId: bookingId,
          qualifiedAt: new Date(),
        },
      });

      // Award points to referrer (default 100 points)
      const referrerRewardPoints = campaign ? Number(campaign.referrerRewardValue) : 100;
      await this.addPointsInternal(
        tx,
        referral.referrerId,
        referrerRewardPoints,
        'REFERRAL',
        'REFERRAL',
        referral.id,
        `ref_reward_${referral.id}`,
      );

      // Award bonus points to referee (default 50 points)
      const refereeRewardPoints = campaign ? Number(campaign.refereeRewardValue) : 50;
      await this.addPointsInternal(
        tx,
        refereeId,
        refereeRewardPoints,
        'BONUS',
        'REFERRAL',
        referral.id,
        `ref_referee_reward_${referral.id}`,
      );

      return updatedRef;
    });
  }

  /**
   * Earns or awards points to user account atomically.
   */
  async earnPoints(
    userId: string,
    points: number,
    referenceType = 'BOOKING',
    referenceId?: string,
    idempotencyKey?: string,
  ) {
    return this.prisma.$transaction(async (tx) => {
      return this.addPointsInternal(tx, userId, points, 'EARN', referenceType, referenceId, idempotencyKey);
    });
  }

  /**
   * Redeems loyalty points for discount (1 point = ₹1 discount).
   */
  async redeemPoints(
    userId: string,
    pointsToRedeem: number,
    referenceType = 'BOOKING',
    referenceId?: string,
    idempotencyKey?: string,
  ) {
    if (pointsToRedeem <= 0) return null;

    return this.prisma.$transaction(async (tx) => {
      const account = await tx.loyaltyAccount.findUnique({
        where: { userId },
      });

      if (!account || account.pointsBalance < pointsToRedeem) {
        throw new BadRequestException(`Insufficient loyalty points balance (Available: ${account?.pointsBalance || 0})`);
      }

      const key = idempotencyKey || `redeem_${userId}_${referenceId || Date.now()}`;

      // Check idempotency
      const existingTx = await tx.loyaltyTransaction.findUnique({
        where: { idempotencyKey: key },
      });
      if (existingTx) return existingTx;

      const newBalance = account.pointsBalance - pointsToRedeem;

      await tx.loyaltyAccount.update({
        where: { id: account.id },
        data: { pointsBalance: newBalance },
      });

      const loyaltyTx = await tx.loyaltyTransaction.create({
        data: {
          accountId: account.id,
          userId,
          type: 'REDEEM',
          points: -pointsToRedeem,
          balanceAfter: newBalance,
          referenceType,
          referenceId,
          idempotencyKey: key,
        },
      });

      return loyaltyTx;
    });
  }

  private async addPointsInternal(
    tx: any,
    userId: string,
    points: number,
    type: string,
    referenceType?: string,
    referenceId?: string,
    idempotencyKey?: string,
  ) {
    let account = await tx.loyaltyAccount.findUnique({ where: { userId } });
    if (!account) {
      account = await tx.loyaltyAccount.create({
        data: { userId, pointsBalance: 0, lifetimeEarned: 0 },
      });
    }

    const key = idempotencyKey || `earn_${userId}_${type}_${referenceId || Date.now()}`;

    const existingTx = await tx.loyaltyTransaction.findUnique({
      where: { idempotencyKey: key },
    });
    if (existingTx) return existingTx;

    const newBalance = account.pointsBalance + points;
    const newLifetime = account.lifetimeEarned + points;

    await tx.loyaltyAccount.update({
      where: { id: account.id },
      data: {
        pointsBalance: newBalance,
        lifetimeEarned: newLifetime,
      },
    });

    return tx.loyaltyTransaction.create({
      data: {
        accountId: account.id,
        userId,
        type,
        points,
        balanceAfter: newBalance,
        referenceType,
        referenceId,
        idempotencyKey: key,
      },
    });
  }
}
