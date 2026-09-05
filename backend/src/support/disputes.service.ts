import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  ConflictException,
  Optional,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { PaymentsService } from '../payments/payments.service';
import { LoyaltyService } from '../loyalty/loyalty.service';
import { AuditService } from '../common/services/audit.service';
import { MetricsService } from '../observability/metrics.service';
import { CreateDisputeDto, DisputeReason } from './dto/create-dispute.dto';
import { ResolveDisputeDto, DisputeDecision } from './dto/resolve-dispute.dto';
import { Decimal } from '@prisma/client/runtime/library';

@Injectable()
export class DisputesService {
  private readonly logger = new Logger(DisputesService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly paymentsService: PaymentsService,
    private readonly loyaltyService: LoyaltyService,
    private readonly auditService: AuditService,
    @Optional() private readonly metricsService?: MetricsService,
  ) {}

  /**
   * Opens a formal dispute case for a customer booking.
   */
  async createDispute(userId: string, dto: CreateDisputeDto) {
    const booking = await this.prisma.booking.findFirst({
      where: { id: dto.bookingId, userId },
      include: { payments: true, facility: { include: { venue: true } } },
    });

    if (!booking) {
      throw new ForbiddenException('Unauthorized access or booking not found');
    }

    const existingDispute = await this.prisma.dispute.findFirst({
      where: { bookingId: dto.bookingId, status: { notIn: ['REJECTED', 'CLOSED'] } },
    });

    if (existingDispute) {
      throw new ConflictException('An active dispute already exists for this booking');
    }

    const payment = booking.payments.find((p) => p.status === 'CAPTURED') || booking.payments[0];

    // Create linked SupportTicket & Dispute
    const ticket = await this.prisma.supportTicket.create({
      data: {
        userId,
        organizationId: booking.organizationId,
        bookingId: booking.id,
        category: 'REFUND_ISSUE',
        subject: `Dispute: ${dto.reason.replace(/_/g, ' ')}`,
        description: dto.description,
        priority: 'HIGH',
        status: 'OPEN',
        messages: {
          create: {
            senderId: userId,
            senderRole: 'CUSTOMER',
            body: dto.description,
          },
        },
      },
    });

    const dispute = await this.prisma.dispute.create({
      data: {
        ticketId: ticket.id,
        bookingId: booking.id,
        paymentId: payment?.id || null,
        organizationId: booking.organizationId,
        customerId: userId,
        reason: dto.reason,
        description: dto.description,
        status: 'OPEN',
      },
      include: {
        ticket: true,
        booking: { include: { facility: { include: { venue: true } } } },
        payment: true,
      },
    });

    await this.auditService.record({
      userId,
      organizationId: booking.organizationId,
      action: 'dispute:created',
      resource: 'dispute',
      resourceId: dispute.id,
      status: 'success',
    });

    return dispute;
  }

  async getDisputeById(userId: string, disputeId: string, isStaff = false, partnerOrgId?: string) {
    const dispute = await this.prisma.dispute.findUnique({
      where: { id: disputeId },
      include: {
        ticket: { include: { messages: { include: { sender: { select: { id: true, fullName: true } } } } } },
        booking: { include: { facility: { include: { venue: true } } } },
        payment: true,
        customer: { select: { id: true, fullName: true, email: true, phoneNumber: true } },
        organization: true,
      },
    });

    if (!dispute) throw new NotFoundException('Dispute case not found');

    if (!isStaff) {
      if (dispute.customerId !== userId) {
        if (partnerOrgId && dispute.organizationId !== partnerOrgId) {
          throw new ForbiddenException('Unauthorized access to dispute case');
        } else if (!partnerOrgId) {
          throw new ForbiddenException('Unauthorized access to dispute case');
        }
      }
    }

    return dispute;
  }

  async partnerResponse(partnerOrgId: string, disputeId: string, responseText: string) {
    const dispute = await this.prisma.dispute.findUnique({ where: { id: disputeId } });
    if (!dispute) throw new NotFoundException('Dispute not found');

    if (dispute.organizationId !== partnerOrgId) {
      throw new ForbiddenException('Unauthorized organization context for dispute');
    }

    const updated = await this.prisma.dispute.update({
      where: { id: disputeId },
      data: {
        partnerResponse: responseText.trim(),
        status: 'UNDER_REVIEW',
      },
    });

    await this.prisma.supportTicket.update({
      where: { id: dispute.ticketId },
      data: { status: 'IN_PROGRESS' },
    });

    return updated;
  }

  /**
   * Resolves dispute with server-authoritative financial refund or goodwill points.
   */
  async resolveDispute(adminId: string, disputeId: string, dto: ResolveDisputeDto) {
    const dispute = await this.prisma.dispute.findUnique({
      where: { id: disputeId },
      include: { booking: { include: { payments: true } }, payment: true },
    });

    if (!dispute) throw new NotFoundException('Dispute case not found');

    if (['DECIDED', 'RESOLVED', 'CLOSED'].includes(dispute.status)) {
      throw new ConflictException(`Dispute is already in terminal status [${dispute.status}]`);
    }

    const { decision, refundAmount, goodwillPoints, resolutionNotes } = dto;

    // 1. Process Financial Refund (FULL_REFUND / PARTIAL_REFUND)
    if (decision === DisputeDecision.FULL_REFUND || decision === DisputeDecision.PARTIAL_REFUND) {
      const payment = dispute.payment || dispute.booking.payments.find((p) => p.status === 'CAPTURED');
      if (!payment) {
        throw new BadRequestException('No captured payment found on booking to issue refund');
      }

      const originalAmount = Number(payment.amount);
      const requestedRefund = decision === DisputeDecision.FULL_REFUND ? originalAmount : (refundAmount || originalAmount);

      if (requestedRefund > originalAmount) {
        throw new BadRequestException(`Refund amount (₹${requestedRefund}) exceeds captured payment amount (₹${originalAmount})`);
      }

      // Execute Payment Refund
      await this.paymentsService.initiateRefund(
        dispute.organizationId,
        payment.id,
        `Dispute Resolution: ${resolutionNotes}`,
      );
    }

    // 2. Process Goodwill Points (GOODWILL_CREDIT)
    if (decision === DisputeDecision.GOODWILL_CREDIT && goodwillPoints && goodwillPoints > 0) {
      await this.loyaltyService.earnPoints(
        dispute.customerId,
        goodwillPoints,
        'DISPUTE_GOODWILL',
        dispute.id,
        `goodwill_dispute_${dispute.id}`,
      );
    }

    // 3. Atomically update Dispute & SupportTicket
    const updatedDispute = await this.prisma.dispute.update({
      where: { id: disputeId },
      data: {
        decision,
        refundAmount: refundAmount ? new Decimal(refundAmount) : null,
        goodwillPoints: goodwillPoints || null,
        status: 'DECIDED',
        decidedById: adminId,
        decidedAt: new Date(),
      },
    });

    await this.prisma.supportTicket.update({
      where: { id: dispute.ticketId },
      data: {
        status: 'RESOLVED',
        assignedAgentId: adminId,
        resolutionNotes,
        closedAt: new Date(),
      },
    });

    await this.auditService.record({
      userId: adminId,
      organizationId: dispute.organizationId,
      action: 'dispute:resolved',
      resource: 'dispute',
      resourceId: disputeId,
      payload: { decision, refundAmount, goodwillPoints, resolutionNotes },
      status: 'success',
    });

    return updatedDispute;
  }

  async getAdminDisputeQueue(filters: {
    status?: string;
    organizationId?: string;
    skip?: number;
    take?: number;
  }) {
    const where: any = {
      ...(filters.status ? { status: filters.status } : {}),
      ...(filters.organizationId ? { organizationId: filters.organizationId } : {}),
    };

    const [items, total] = await Promise.all([
      this.prisma.dispute.findMany({
        where,
        include: {
          customer: { select: { id: true, fullName: true, email: true } },
          booking: { include: { facility: { include: { venue: true } } } },
          organization: true,
          ticket: true,
        },
        orderBy: { createdAt: 'desc' },
        skip: filters.skip,
        take: filters.take,
      }),
      this.prisma.dispute.count({ where }),
    ]);

    return { items, total };
  }
}
