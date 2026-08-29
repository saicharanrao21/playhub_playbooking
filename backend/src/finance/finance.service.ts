import { Injectable, Logger, ConflictException, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { FinancialTransactionType, PayoutStatus } from '@prisma/client';
import { Decimal } from '@prisma/client/runtime/library';

@Injectable()
export class FinanceService {
  private readonly logger = new Logger(FinanceService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Records a payment financial event in the ledger.
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
      const config = await tx.commissionConfig.findFirst({
        where: { OR: [{ organizationId }, { organizationId: null }], isActive: true },
        orderBy: { organizationId: 'desc' }, // Specific organization first
      });

      const percentage = config?.percentage ? Number(config.percentage) : 10.0; // Default 10%
      const commissionAmount = Number(amount) * (percentage / 100);
      const partnerNet = Number(amount) - commissionAmount;

      // 3. Create High-Level Transaction
      const transaction = await tx.financialTransaction.create({
        data: {
          organizationId,
          userId,
          paymentId,
          bookingId,
          type: FinancialTransactionType.PAYMENT,
          amount: new Decimal(amount),
          currency: 'INR',
          idempotencyKey,
          description: `Booking payment for ${bookingId}`,
          metadata: {
            commissionPercentage: percentage,
            commissionAmount,
            partnerNet,
          },
        },
      });

      // 4. Create Ledger Entries (Double-Entry)
      // Account: CASH/BANK_DEPOSIT (Asset) - Debit
      await tx.ledgerEntry.create({
        data: {
          financialTransactionId: transaction.id,
          account: 'PAYMENT_CLEARING',
          debit: new Decimal(amount),
          credit: 0,
          organizationId,
        },
      });

      // Account: PARTNER_PAYABLE (Liability) - Credit
      await tx.ledgerEntry.create({
        data: {
          financialTransactionId: transaction.id,
          account: 'PARTNER_PAYABLE',
          debit: 0,
          credit: new Decimal(partnerNet),
          organizationId,
        },
      });

      // Account: PLATFORM_REVENUE (Revenue) - Credit
      await tx.ledgerEntry.create({
        data: {
          financialTransactionId: transaction.id,
          account: 'PLATFORM_REVENUE',
          debit: 0,
          credit: new Decimal(commissionAmount),
          // We can link this to the organization or keep it global
        },
      });

      return transaction;
    });
  }

  async getPartnerBalance(organizationId: string) {
    const result = await this.prisma.ledgerEntry.aggregate({
      where: {
        organizationId,
        account: 'PARTNER_PAYABLE',
      },
      _sum: {
        debit: true,
        credit: true,
      },
    });

    const credits = result._sum.credit ? Number(result._sum.credit) : 0;
    const debits = result._sum.debit ? Number(result._sum.debit) : 0;

    return {
      availableBalance: credits - debits,
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
      },
    });
  }

  async getTransactionCount(organizationId: string) {
    return this.prisma.financialTransaction.count({
      where: { organizationId },
    });
  }
}
