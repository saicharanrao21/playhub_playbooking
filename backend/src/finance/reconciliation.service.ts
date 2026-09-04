import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ReconciliationQueryDto } from './dto/reconciliation-query.dto';
import { PaymentStatus, FinancialTransactionType, PayoutStatus } from '@prisma/client';

export interface DiscrepancyItem {
  code: string;
  severity: 'HIGH' | 'MEDIUM' | 'LOW';
  description: string;
  entityType: 'PAYMENT' | 'FINANCIAL_TRANSACTION' | 'LEDGER_ENTRY' | 'PAYOUT' | 'SETTLEMENT';
  entityId: string;
  organizationId?: string;
  details?: Record<string, any>;
}

@Injectable()
export class ReconciliationService {
  private readonly logger = new Logger(ReconciliationService.name);

  constructor(private prisma: PrismaService) {}

  async runReconciliation(query: ReconciliationQueryDto) {
    const { startDate, endDate, organizationId, provider } = query;

    const dateFilter: any = {};
    if (startDate) dateFilter.gte = new Date(startDate);
    if (endDate) dateFilter.lte = new Date(endDate);

    const paymentWhere: any = {
      ...(organizationId ? { organizationId } : {}),
      ...(provider ? { provider: provider.toUpperCase() as any } : {}),
      ...(Object.keys(dateFilter).length > 0 ? { createdAt: dateFilter } : {}),
    };

    const transactionWhere: any = {
      ...(organizationId ? { organizationId } : {}),
      ...(Object.keys(dateFilter).length > 0 ? { createdAt: dateFilter } : {}),
    };

    const discrepancies: DiscrepancyItem[] = [];

    // 1. Fetch captured payments & financial transactions
    const [capturedPayments, transactions, allPayouts] = await Promise.all([
      this.prisma.payment.findMany({
        where: { ...paymentWhere, status: PaymentStatus.CAPTURED },
        include: { financialTransactions: true, booking: true },
      }),
      this.prisma.financialTransaction.findMany({
        where: transactionWhere,
        include: { ledgerEntries: true, payment: true, booking: true },
      }),
      this.prisma.payout.findMany({
        where: {
          ...(organizationId ? { organizationId } : {}),
          status: { in: [PayoutStatus.COMPLETED, PayoutStatus.PROCESSING, PayoutStatus.PENDING] },
        },
      }),
    ]);

    // Check 1: Captured payments without a FinancialTransaction of type PAYMENT
    for (const payment of capturedPayments) {
      const hasPaymentTx = payment.financialTransactions.some(
        (tx) => tx.type === FinancialTransactionType.PAYMENT,
      );
      if (!hasPaymentTx) {
        discrepancies.push({
          code: 'UNRECORDED_PAYMENT',
          severity: 'HIGH',
          description: `Captured payment ${payment.id} has no ledger financial transaction recorded`,
          entityType: 'PAYMENT',
          entityId: payment.id,
          organizationId: payment.organizationId,
          details: { amount: Number(payment.amount), bookingId: payment.bookingId },
        });
      }
    }

    // Check 2: Unbalanced ledger transactions (Debit != Credit)
    for (const tx of transactions) {
      const totalDebit = tx.ledgerEntries.reduce((sum, e) => sum + Number(e.debit), 0);
      const totalCredit = tx.ledgerEntries.reduce((sum, e) => sum + Number(e.credit), 0);

      // Using cents precision check
      if (Math.abs(totalDebit - totalCredit) > 0.009) {
        discrepancies.push({
          code: 'UNBALANCED_LEDGER_TRANSACTION',
          severity: 'HIGH',
          description: `Transaction ${tx.id} ledger entries are unbalanced: Dr ${totalDebit} vs Cr ${totalCredit}`,
          entityType: 'FINANCIAL_TRANSACTION',
          entityId: tx.id,
          organizationId: tx.organizationId,
          details: { totalDebit, totalCredit, diff: totalDebit - totalCredit },
        });
      }

      // Check 3: Amount Mismatch between Payment and FinancialTransaction
      if (tx.payment && Math.abs(Number(tx.amount) - Number(tx.payment.amount)) > 0.009) {
        discrepancies.push({
          code: 'PAYMENT_AMOUNT_MISMATCH',
          severity: 'HIGH',
          description: `Financial transaction ${tx.id} amount (${tx.amount}) does not match payment amount (${tx.payment.amount})`,
          entityType: 'FINANCIAL_TRANSACTION',
          entityId: tx.id,
          organizationId: tx.organizationId,
          details: { txAmount: Number(tx.amount), paymentAmount: Number(tx.payment.amount) },
        });
      }
    }

    // Check 4: Refunded payments without REFUND financial transaction
    const refundedPayments = await this.prisma.payment.findMany({
      where: { ...paymentWhere, status: PaymentStatus.REFUNDED },
      include: { financialTransactions: true },
    });

    for (const payment of refundedPayments) {
      const hasRefundTx = payment.financialTransactions.some(
        (tx) => tx.type === FinancialTransactionType.REFUND,
      );
      if (!hasRefundTx) {
        discrepancies.push({
          code: 'UNRECORDED_REFUND',
          severity: 'HIGH',
          description: `Refunded payment ${payment.id} has no corresponding REFUND financial transaction in ledger`,
          entityType: 'PAYMENT',
          entityId: payment.id,
          organizationId: payment.organizationId,
          details: { amount: Number(payment.amount) },
        });
      }
    }

    // Totals Aggregation
    const grossPayments = capturedPayments.reduce((sum, p) => sum + Number(p.amount), 0);
    const totalRefundsAmount = refundedPayments.reduce((sum, p) => sum + Number(p.amount), 0);

    const revenueLedgerEntries = await this.prisma.ledgerEntry.aggregate({
      where: {
        account: 'PLATFORM_REVENUE',
        ...(organizationId ? { organizationId } : {}),
      },
      _sum: { credit: true, debit: true },
    });
    const totalCommission =
      (Number(revenueLedgerEntries._sum.credit) || 0) -
      (Number(revenueLedgerEntries._sum.debit) || 0);

    const payableLedgerEntries = await this.prisma.ledgerEntry.aggregate({
      where: {
        account: 'PARTNER_PAYABLE',
        ...(organizationId ? { organizationId } : {}),
      },
      _sum: { credit: true, debit: true },
    });
    const netPartnerPayable =
      (Number(payableLedgerEntries._sum.credit) || 0) -
      (Number(payableLedgerEntries._sum.debit) || 0);

    const totalCompletedPayouts = allPayouts
      .filter((p) => p.status === PayoutStatus.COMPLETED)
      .reduce((sum, p) => sum + Number(p.amount), 0);

    const outstandingBalance = netPartnerPayable;

    return {
      reconciliationStatus:
        discrepancies.length === 0 ? 'HEALTHY' : 'DISCREPANCIES_FOUND',
      totalChecked: capturedPayments.length + transactions.length + refundedPayments.length,
      matchedCount:
        capturedPayments.length +
        transactions.length +
        refundedPayments.length -
        discrepancies.length,
      discrepancyCount: discrepancies.length,
      totals: {
        grossPayments,
        totalRefunds: totalRefundsAmount,
        totalCommission,
        netPartnerPayable,
        totalCompletedPayouts,
        outstandingBalance,
        currency: 'INR',
      },
      discrepancies,
    };
  }
}
