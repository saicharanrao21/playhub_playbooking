import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { FinanceService } from './finance.service';
import { RequestPayoutDto } from './dto/request-payout.dto';
import { PayoutStatus, KYCStatus, FinancialTransactionType } from '@prisma/client';
import { Decimal } from '@prisma/client/runtime/library';
import { AuditService } from '../common/services/audit.service';

@Injectable()
export class PayoutService {
  private readonly logger = new Logger(PayoutService.name);

  constructor(
    private prisma: PrismaService,
    private financeService: FinanceService,
    private auditService: AuditService,
  ) {}

  async initiatePayout(organizationId: string, dto: RequestPayoutDto, requestedById?: string) {
    const { amount, settlementId } = dto;

    // 1. Verify Partner KYC Status
    const org = await this.prisma.organization.findUnique({
      where: { id: organizationId },
    });

    if (!org) throw new NotFoundException('Organization not found');

    if (org.kycStatus !== KYCStatus.APPROVED) {
      throw new ForbiddenException(
        `Payouts require APPROVED KYC status. Current KYC status: ${org.kycStatus}`,
      );
    }

    // 2. Verify Bank Details present
    if (!org.accountNumber || !org.ifscCode || !org.accountHolderName) {
      throw new BadRequestException('Settlement bank details (Account number, IFSC) are incomplete');
    }

    // 3. Verify Available Balance
    const summary = await this.financeService.getPartnerFinancialSummary(organizationId);
    if (amount > summary.availableBalance) {
      throw new BadRequestException(
        `Requested payout amount (₹${amount}) exceeds available payable balance (₹${summary.availableBalance})`,
      );
    }

    // 4. Create Payout + FinancialTransaction + Ledger Entry in transaction
    const idempotencyKey = `payout_${organizationId}_${Date.now()}`;

    return this.prisma.$transaction(async (tx) => {
      const payout = await tx.payout.create({
        data: {
          organizationId,
          settlementId: settlementId || null,
          amount: new Decimal(amount),
          currency: 'INR',
          status: PayoutStatus.PROCESSING,
          provider: 'MOCK',
          initiatedAt: new Date(),
          metadata: { requestedById },
        },
      });

      // Create PAYOUT FinancialTransaction
      const finTx = await tx.financialTransaction.create({
        data: {
          organizationId,
          createdById: requestedById,
          payoutId: payout.id,
          settlementId: settlementId || null,
          type: FinancialTransactionType.PAYOUT,
          amount: new Decimal(amount),
          currency: 'INR',
          description: `Payout #${payout.id} initiated to bank account ${org.accountNumber.slice(-4)}`,
          idempotencyKey,
        },
      });

      // Double-Entry Ledger: Debit PARTNER_PAYABLE (reducing liability), Credit PAYOUT_PENDING
      await tx.ledgerEntry.create({
        data: {
          financialTransactionId: finTx.id,
          account: 'PARTNER_PAYABLE',
          debit: new Decimal(amount),
          credit: 0,
          organizationId,
        },
      });

      await tx.ledgerEntry.create({
        data: {
          financialTransactionId: finTx.id,
          account: 'PAYOUT_PENDING',
          debit: 0,
          credit: new Decimal(amount),
          organizationId,
        },
      });

      await this.auditService.record({
        userId: requestedById,
        organizationId,
        action: 'finance:payout_initiated',
        resource: 'payout',
        resourceId: payout.id,
        payload: { amount, settlementId },
        status: 'success',
      });

      return payout;
    });
  }

  async completePayout(payoutId: string, providerReference: string, adminId?: string) {
    const payout = await this.prisma.payout.findUnique({ where: { id: payoutId } });
    if (!payout) throw new NotFoundException('Payout not found');

    if (payout.status === PayoutStatus.COMPLETED) return payout;

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.payout.update({
        where: { id: payoutId },
        data: {
          status: PayoutStatus.COMPLETED,
          providerReference,
          completedAt: new Date(),
        },
      });

      // Find the Payout transaction to resolve clearing
      const finTx = await tx.financialTransaction.findFirst({
        where: { payoutId },
      });

      if (finTx) {
        // Debit PAYOUT_PENDING, Credit PAYMENT_CLEARING
        await tx.ledgerEntry.create({
          data: {
            financialTransactionId: finTx.id,
            account: 'PAYOUT_PENDING',
            debit: payout.amount,
            credit: 0,
            organizationId: payout.organizationId,
          },
        });
        await tx.ledgerEntry.create({
          data: {
            financialTransactionId: finTx.id,
            account: 'PAYMENT_CLEARING',
            debit: 0,
            credit: payout.amount,
            organizationId: payout.organizationId,
          },
        });
      }

      await this.auditService.record({
        userId: adminId,
        organizationId: payout.organizationId,
        action: 'finance:payout_completed',
        resource: 'payout',
        resourceId: payoutId,
        payload: { providerReference },
        status: 'success',
      });

      return updated;
    });
  }

  async failPayout(payoutId: string, reason: string, adminId?: string) {
    const payout = await this.prisma.payout.findUnique({ where: { id: payoutId } });
    if (!payout) throw new NotFoundException('Payout not found');

    if (payout.status === PayoutStatus.FAILED) return payout;

    return this.prisma.$transaction(async (tx) => {
      const updated = await tx.payout.update({
        where: { id: payoutId },
        data: {
          status: PayoutStatus.FAILED,
          failureReason: reason,
        },
      });

      // Safely restore partner payable balance via reversal entries!
      const finTx = await tx.financialTransaction.findFirst({
        where: { payoutId },
      });

      if (finTx) {
        // Debit PAYOUT_PENDING, Credit PARTNER_PAYABLE (restoring partner payable!)
        await tx.ledgerEntry.create({
          data: {
            financialTransactionId: finTx.id,
            account: 'PAYOUT_PENDING',
            debit: payout.amount,
            credit: 0,
            organizationId: payout.organizationId,
          },
        });
        await tx.ledgerEntry.create({
          data: {
            financialTransactionId: finTx.id,
            account: 'PARTNER_PAYABLE',
            debit: 0,
            credit: payout.amount,
            organizationId: payout.organizationId,
          },
        });
      }

      await this.auditService.record({
        userId: adminId,
        organizationId: payout.organizationId,
        action: 'finance:payout_failed',
        resource: 'payout',
        resourceId: payoutId,
        payload: { reason },
        status: 'success',
      });

      return updated;
    });
  }

  async getPayouts(organizationId: string) {
    return this.prisma.payout.findMany({
      where: { organizationId },
      orderBy: { createdAt: 'desc' },
      include: { settlement: true },
    });
  }

  async getAllPayouts() {
    return this.prisma.payout.findMany({
      orderBy: { createdAt: 'desc' },
      include: { organization: true, settlement: true },
    });
  }
}
