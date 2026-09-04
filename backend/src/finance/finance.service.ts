import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  FinancialTransactionType,
  PayoutStatus,
  PaymentStatus,
  CommissionConfig,
} from '@prisma/client';
import { Decimal } from '@prisma/client/runtime/library';
import { CreateCommissionConfigDto } from './dto/create-commission-config.dto';
import { CreateAdjustmentDto, AdjustmentDirection } from './dto/create-adjustment.dto';

@Injectable()
export class FinanceService {
  private readonly logger = new Logger(FinanceService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Resolves the authoritative commission config rule for an organization.
   * Prefers org-specific active rule over global default rule, sorted by priority.
   */
  async resolveCommissionConfig(organizationId?: string): Promise<{ percentage: number; fixedFee: number }> {
    const now = new Date();

    const rules = await this.prisma.commissionConfig.findMany({
      where: {
        isActive: true,
        OR: [
          ...(organizationId ? [{ organizationId }] : []),
          { organizationId: null },
        ],
        AND: [
          { OR: [{ effectiveFrom: null }, { effectiveFrom: { lte: now } }] },
          { OR: [{ effectiveTo: null }, { effectiveTo: { gte: now } }] },
        ],
      },
      orderBy: [
        { organizationId: 'desc' }, // Non-null organizationId comes first
        { priority: 'desc' },
        { createdAt: 'desc' },
      ],
    });

    if (rules.length === 0) {
      // Default fallback: 10% platform fee, 0 fixed fee
      return { percentage: 10.0, fixedFee: 0 };
    }

    const matched = rules[0];
    return {
      percentage: Number(matched.percentage),
      fixedFee: Number(matched.fixedFee),
    };
  }

  /**
   * Records a payment financial transaction & double-entry ledger entries.
   */
  async recordPayment(payload: {
    paymentId: string;
    bookingId: string;
    organizationId: string;
    amount: number | Decimal;
    userId?: string;
  }) {
    const { paymentId, bookingId, organizationId, amount, userId } = payload;
    const idempotencyKey = `pay_${paymentId}`;

    return this.prisma.$transaction(async (tx) => {
      // 1. Idempotency Check
      const existing = await tx.financialTransaction.findUnique({
        where: { idempotencyKey },
      });
      if (existing) return existing;

      // 2. Resolve Commission
      const { percentage, fixedFee } = await this.resolveCommissionConfig(organizationId);

      const grossAmount = Number(amount);
      const commissionAmount = Math.round((grossAmount * (percentage / 100) + fixedFee) * 100) / 100;
      const partnerNet = grossAmount - commissionAmount;

      // 3. Create High-Level Transaction
      const transaction = await tx.financialTransaction.create({
        data: {
          organizationId,
          userId,
          paymentId,
          bookingId,
          type: FinancialTransactionType.PAYMENT,
          amount: new Decimal(grossAmount),
          currency: 'INR',
          idempotencyKey,
          description: `Booking payment for ${bookingId}`,
          metadata: {
            commissionPercentage: percentage,
            fixedFee,
            commissionAmount,
            partnerNet,
          },
        },
      });

      // 4. Create Ledger Entries (Double-Entry Balance: Dr = Cr = grossAmount)
      // Account: PAYMENT_CLEARING (Asset) - Debit gross
      await tx.ledgerEntry.create({
        data: {
          financialTransactionId: transaction.id,
          account: 'PAYMENT_CLEARING',
          debit: new Decimal(grossAmount),
          credit: 0,
          organizationId,
        },
      });

      // Account: PARTNER_PAYABLE (Liability) - Credit net
      await tx.ledgerEntry.create({
        data: {
          financialTransactionId: transaction.id,
          account: 'PARTNER_PAYABLE',
          debit: 0,
          credit: new Decimal(partnerNet),
          organizationId,
        },
      });

      // Account: PLATFORM_REVENUE (Revenue) - Credit commission
      await tx.ledgerEntry.create({
        data: {
          financialTransactionId: transaction.id,
          account: 'PLATFORM_REVENUE',
          debit: 0,
          credit: new Decimal(commissionAmount),
          organizationId,
        },
      });

      return transaction;
    });
  }

  /**
   * Records a refund financial transaction & reversal ledger entries.
   * Double-entry balanced: Dr PARTNER_PAYABLE (partner net), Dr PLATFORM_REVENUE (commission), Cr PAYMENT_CLEARING (gross refund).
   */
  async recordRefund(payload: {
    paymentId: string;
    bookingId: string;
    organizationId: string;
    amount: number | Decimal;
    reason?: string;
    userId?: string;
    createdById?: string;
  }) {
    const { paymentId, bookingId, organizationId, amount, reason, userId, createdById } = payload;
    const grossRefund = Number(amount);

    return this.prisma.$transaction(async (tx) => {
      // 1. Verify Payment & existing FinancialTransaction
      const payment = await tx.payment.findUnique({
        where: { id: paymentId },
        include: { financialTransactions: true, booking: true },
      });

      if (!payment) throw new NotFoundException('Payment record not found');

      const originalPaymentTx = payment.financialTransactions.find(
        (t) => t.type === FinancialTransactionType.PAYMENT,
      );

      if (!originalPaymentTx) {
        throw new BadRequestException('Cannot record refund for unrecorded payment');
      }

      // Check cumulative refunds to prevent over-refunding
      const existingRefundTxs = payment.financialTransactions.filter(
        (t) => t.type === FinancialTransactionType.REFUND,
      );
      const totalRefundedSoFar = existingRefundTxs.reduce((sum, t) => sum + Number(t.amount), 0);
      const capturedAmount = Number(payment.amount);

      if (totalRefundedSoFar + grossRefund > capturedAmount + 0.01) {
        throw new BadRequestException(
          `Refund amount (${grossRefund}) exceeds remaining refundable amount (${capturedAmount - totalRefundedSoFar})`,
        );
      }

      // Proportional Commission & Net Reversal
      const originalMeta = (originalPaymentTx.metadata as any) || {};
      const commissionPct = originalMeta.commissionPercentage ?? 10.0;
      const commissionReversed = Math.round((grossRefund * (commissionPct / 100)) * 100) / 100;
      const partnerNetReversed = grossRefund - commissionReversed;

      const idempotencyKey = `refund_${paymentId}_${totalRefundedSoFar + grossRefund}`;

      // 2. Create REFUND FinancialTransaction
      const refundTransaction = await tx.financialTransaction.create({
        data: {
          organizationId,
          userId: userId || payment.booking?.userId,
          createdById,
          paymentId,
          bookingId,
          type: FinancialTransactionType.REFUND,
          amount: new Decimal(grossRefund),
          currency: 'INR',
          description: `Refund for booking ${bookingId}: ${reason || 'User/Partner requested'}`,
          reversalOfId: originalPaymentTx.id,
          idempotencyKey,
          metadata: {
            grossRefund,
            commissionPct,
            commissionReversed,
            partnerNetReversed,
            reason,
          },
        },
      });

      // 3. Create Balanced Ledger Entries
      // Debit PARTNER_PAYABLE (reducing liability to partner)
      await tx.ledgerEntry.create({
        data: {
          financialTransactionId: refundTransaction.id,
          account: 'PARTNER_PAYABLE',
          debit: new Decimal(partnerNetReversed),
          credit: 0,
          organizationId,
        },
      });

      // Debit PLATFORM_REVENUE (reversing platform commission)
      await tx.ledgerEntry.create({
        data: {
          financialTransactionId: refundTransaction.id,
          account: 'PLATFORM_REVENUE',
          debit: new Decimal(commissionReversed),
          credit: 0,
          organizationId,
        },
      });

      // Credit PAYMENT_CLEARING (reversing clearing asset / customer refund)
      await tx.ledgerEntry.create({
        data: {
          financialTransactionId: refundTransaction.id,
          account: 'PAYMENT_CLEARING',
          debit: 0,
          credit: new Decimal(grossRefund),
          organizationId,
        },
      });

      return refundTransaction;
    });
  }

  /**
   * Records a manual governed adjustment (Credit/Debit) by an admin.
   */
  async recordAdjustment(createdById: string, dto: CreateAdjustmentDto) {
    const { organizationId, amount, direction, reason } = dto;
    const idempotencyKey = `adj_${organizationId}_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;

    return this.prisma.$transaction(async (tx) => {
      const transaction = await tx.financialTransaction.create({
        data: {
          organizationId,
          createdById,
          type: FinancialTransactionType.ADJUSTMENT,
          amount: new Decimal(amount),
          currency: 'INR',
          description: `Admin Adjustment (${direction}): ${reason}`,
          idempotencyKey,
          metadata: { direction, reason, createdById },
        },
      });

      if (direction === AdjustmentDirection.CREDIT) {
        // Partner Credit Adjustment (Giving goodwill/bonus to partner)
        // Debit PLATFORM_ADJUSTMENT_EXPENSE, Credit PARTNER_PAYABLE
        await tx.ledgerEntry.create({
          data: {
            financialTransactionId: transaction.id,
            account: 'PLATFORM_ADJUSTMENT_EXPENSE',
            debit: new Decimal(amount),
            credit: 0,
            organizationId,
          },
        });
        await tx.ledgerEntry.create({
          data: {
            financialTransactionId: transaction.id,
            account: 'PARTNER_PAYABLE',
            debit: 0,
            credit: new Decimal(amount),
            organizationId,
          },
        });
      } else {
        // Partner Debit Adjustment (Deducting money/penalty from partner)
        // Debit PARTNER_PAYABLE, Credit PLATFORM_ADJUSTMENT_INCOME
        await tx.ledgerEntry.create({
          data: {
            financialTransactionId: transaction.id,
            account: 'PARTNER_PAYABLE',
            debit: new Decimal(amount),
            credit: 0,
            organizationId,
          },
        });
        await tx.ledgerEntry.create({
          data: {
            financialTransactionId: transaction.id,
            account: 'PLATFORM_ADJUSTMENT_INCOME',
            debit: 0,
            credit: new Decimal(amount),
            organizationId,
          },
        });
      }

      await tx.auditLog.create({
        data: {
          userId: createdById,
          organizationId,
          action: `finance:adjustment:${direction.toLowerCase()}`,
          resource: 'financial_transaction',
          resourceId: transaction.id,
          payload: { amount, direction, reason },
          status: 'success',
        },
      });

      return transaction;
    });
  }

  /**
   * Computes authoritative financial summary for an organization from ledger records.
   */
  async getPartnerFinancialSummary(organizationId: string) {
    const [payableAgg, revenueAgg, completedPayoutsAgg, settlementsCount] = await Promise.all([
      this.prisma.ledgerEntry.aggregate({
        where: { organizationId, account: 'PARTNER_PAYABLE' },
        _sum: { credit: true, debit: true },
      }),
      this.prisma.ledgerEntry.aggregate({
        where: { organizationId, account: 'PLATFORM_REVENUE' },
        _sum: { credit: true, debit: true },
      }),
      this.prisma.payout.aggregate({
        where: { organizationId, status: PayoutStatus.COMPLETED },
        _sum: { amount: true },
      }),
      this.prisma.settlement.count({
        where: { organizationId },
      }),
    ]);

    const grossPayableCredits = Number(payableAgg._sum.credit) || 0;
    const grossPayableDebits = Number(payableAgg._sum.debit) || 0;
    const netAvailablePayable = grossPayableCredits - grossPayableDebits;

    const totalCommissionEarned =
      (Number(revenueAgg._sum.credit) || 0) - (Number(revenueAgg._sum.debit) || 0);

    const totalCompletedPayouts = Number(completedPayoutsAgg._sum.amount) || 0;

    // Fetch transactions count
    const totalTransactions = await this.prisma.financialTransaction.count({
      where: { organizationId },
    });

    return {
      availableBalance: netAvailablePayable,
      grossEarnings: grossPayableCredits + totalCommissionEarned,
      totalCommission: totalCommissionEarned,
      totalPaidOut: totalCompletedPayouts,
      settlementsCount,
      totalTransactions,
      currency: 'INR',
    };
  }

  async getPartnerBalance(organizationId: string) {
    const summary = await this.getPartnerFinancialSummary(organizationId);
    return {
      availableBalance: summary.availableBalance,
      currency: 'INR',
    };
  }

  async getTransactions(organizationId: string, filters: { skip?: number; take?: number }) {
    return this.prisma.financialTransaction.findMany({
      where: { organizationId },
      orderBy: { createdAt: 'desc' },
      skip: filters.skip,
      take: filters.take,
      include: {
        payment: true,
        booking: true,
        ledgerEntries: true,
      },
    });
  }

  async getTransactionCount(organizationId: string) {
    return this.prisma.financialTransaction.count({
      where: { organizationId },
    });
  }

  // Commission Config Management
  async createCommissionConfig(dto: CreateCommissionConfigDto) {
    return this.prisma.commissionConfig.create({
      data: {
        organizationId: dto.organizationId || null,
        name: dto.name,
        percentage: new Decimal(dto.percentage),
        fixedFee: new Decimal(dto.fixedFee || 0),
        currency: dto.currency || 'INR',
        effectiveFrom: dto.effectiveFrom ? new Date(dto.effectiveFrom) : null,
        effectiveTo: dto.effectiveTo ? new Date(dto.effectiveTo) : null,
        priority: dto.priority || 0,
        isActive: dto.isActive !== undefined ? dto.isActive : true,
      },
    });
  }

  async updateCommissionConfig(id: string, dto: Partial<CreateCommissionConfigDto>) {
    const existing = await this.prisma.commissionConfig.findUnique({ where: { id } });
    if (!existing) throw new NotFoundException('Commission configuration not found');

    return this.prisma.commissionConfig.update({
      where: { id },
      data: {
        ...(dto.name ? { name: dto.name } : {}),
        ...(dto.percentage !== undefined ? { percentage: new Decimal(dto.percentage) } : {}),
        ...(dto.fixedFee !== undefined ? { fixedFee: new Decimal(dto.fixedFee) } : {}),
        ...(dto.effectiveFrom ? { effectiveFrom: new Date(dto.effectiveFrom) } : {}),
        ...(dto.effectiveTo ? { effectiveTo: new Date(dto.effectiveTo) } : {}),
        ...(dto.priority !== undefined ? { priority: dto.priority } : {}),
        ...(dto.isActive !== undefined ? { isActive: dto.isActive } : {}),
      },
    });
  }

  async getCommissionConfigs() {
    return this.prisma.commissionConfig.findMany({
      orderBy: [{ priority: 'desc' }, { createdAt: 'desc' }],
      include: { organization: true },
    });
  }
}
