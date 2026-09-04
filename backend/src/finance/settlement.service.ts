import { Injectable, Logger, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateSettlementDto } from './dto/create-settlement.dto';
import { Decimal } from '@prisma/client/runtime/library';

@Injectable()
export class SettlementService {
  private readonly logger = new Logger(SettlementService.name);

  constructor(private prisma: PrismaService) {}

  async createSettlement(dto: CreateSettlementDto) {
    const { organizationId, startDate, endDate } = dto;
    const start = new Date(startDate);
    const end = new Date(endDate);

    if (start >= end) {
      throw new BadRequestException('Start date must be before end date');
    }

    return this.prisma.$transaction(async (tx) => {
      // Find all transactions for org between startDate & endDate that are NOT yet settled
      const transactions = await tx.financialTransaction.findMany({
        where: {
          organizationId,
          settlementId: null,
          createdAt: { gte: start, lte: end },
        },
      });

      if (transactions.length === 0) {
        throw new BadRequestException('No eligible unsettled financial transactions found in date range');
      }

      let grossAmount = 0;
      let commission = 0;

      for (const t of transactions) {
        const amt = Number(t.amount);
        const meta = (t.metadata as any) || {};
        if (t.type === 'PAYMENT') {
          grossAmount += amt;
          commission += meta.commissionAmount || 0;
        } else if (t.type === 'REFUND') {
          grossAmount -= amt;
          commission -= meta.commissionReversed || 0;
        }
      }

      const netAmount = grossAmount - commission;

      // Create Settlement
      const settlement = await tx.settlement.create({
        data: {
          organizationId,
          status: 'FINALIZED',
          startDate: start,
          endDate: end,
          grossAmount: new Decimal(grossAmount),
          commission: new Decimal(commission),
          netAmount: new Decimal(netAmount),
          currency: 'INR',
          finalizedAt: new Date(),
        },
      });

      // Update transactions linking them to this settlement
      await tx.financialTransaction.updateMany({
        where: {
          id: { in: transactions.map((t) => t.id) },
        },
        data: {
          settlementId: settlement.id,
        },
      });

      return settlement;
    });
  }

  async getSettlements(organizationId: string) {
    return this.prisma.settlement.findMany({
      where: { organizationId },
      orderBy: { createdAt: 'desc' },
      include: {
        payout: true,
        transactions: true,
      },
    });
  }

  async getAllSettlements() {
    return this.prisma.settlement.findMany({
      orderBy: { createdAt: 'desc' },
      include: {
        organization: true,
        payout: true,
      },
    });
  }
}
