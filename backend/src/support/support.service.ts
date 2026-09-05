import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Optional,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../common/services/audit.service';
import { MetricsService } from '../observability/metrics.service';
import { CreateTicketDto, TicketCategory, TicketPriority } from './dto/create-ticket.dto';

@Injectable()
export class SupportService {
  private readonly logger = new Logger(SupportService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly auditService: AuditService,
    @Optional() private readonly metricsService?: MetricsService,
  ) {}

  /**
   * Creates a new support ticket and initial customer message.
   */
  async createTicket(userId: string, dto: CreateTicketDto) {
    let organizationId: string | null = null;

    if (dto.bookingId) {
      const booking = await this.prisma.booking.findFirst({
        where: { id: dto.bookingId, userId },
      });
      if (!booking) {
        throw new ForbiddenException('Unauthorized access to booking for support ticket');
      }
      organizationId = booking.organizationId;
    }

    const ticket = await this.prisma.supportTicket.create({
      data: {
        userId,
        organizationId,
        bookingId: dto.bookingId || null,
        category: dto.category || TicketCategory.OTHER,
        subject: dto.subject,
        description: dto.description,
        priority: dto.priority || TicketPriority.MEDIUM,
        status: 'OPEN',
        messages: {
          create: {
            senderId: userId,
            senderRole: 'CUSTOMER',
            body: dto.description,
          },
        },
      },
      include: {
        messages: true,
        booking: {
          include: { facility: { include: { venue: true } } },
        },
      },
    });

    await this.auditService.record({
      userId,
      organizationId: organizationId || undefined,
      action: 'support:ticket_created',
      resource: 'support_ticket',
      resourceId: ticket.id,
      status: 'success',
    });

    if (this.metricsService) {
      this.metricsService.cacheOperationsTotal.inc({ operation: 'ticket_create', result: 'success' });
    }

    return ticket;
  }

  async getUserTickets(userId: string, skip = 0, take = 20) {
    const [items, total] = await Promise.all([
      this.prisma.supportTicket.findMany({
        where: { userId },
        include: {
          booking: {
            include: { facility: { include: { venue: true } } },
          },
          dispute: true,
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take,
      }),
      this.prisma.supportTicket.count({ where: { userId } }),
    ]);

    return { items, total };
  }

  async getTicketDetails(userId: string, ticketId: string, isStaff = false, partnerOrgId?: string) {
    const ticket = await this.prisma.supportTicket.findUnique({
      where: { id: ticketId },
      include: {
        user: { select: { id: true, fullName: true, email: true, phoneNumber: true } },
        booking: { include: { facility: { include: { venue: true } }, payments: true } },
        messages: { include: { sender: { select: { id: true, fullName: true } } }, orderBy: { createdAt: 'asc' } },
        dispute: true,
      },
    });

    if (!ticket) {
      throw new NotFoundException('Support ticket not found');
    }

    // Tenant / Ownership Guard Check
    if (!isStaff) {
      if (ticket.userId !== userId) {
        if (partnerOrgId && ticket.organizationId !== partnerOrgId) {
          throw new ForbiddenException('Unauthorized access to support ticket');
        } else if (!partnerOrgId) {
          throw new ForbiddenException('Unauthorized access to support ticket');
        }
      }
    }

    return ticket;
  }

  async addMessage(
    userId: string,
    senderRole: string,
    ticketId: string,
    body: string,
    attachments?: any,
  ) {
    const ticket = await this.prisma.supportTicket.findUnique({ where: { id: ticketId } });
    if (!ticket) throw new NotFoundException('Support ticket not found');

    const message = await this.prisma.supportMessage.create({
      data: {
        ticketId,
        senderId: userId,
        senderRole,
        body: body.trim(),
        attachments: attachments || null,
      },
      include: { sender: { select: { id: true, fullName: true } } },
    });

    // Update Ticket status
    let nextStatus = ticket.status;
    if (senderRole === 'CUSTOMER' && ticket.status === 'WAITING_FOR_CUSTOMER') {
      nextStatus = 'IN_PROGRESS';
    } else if (senderRole === 'SUPPORT' || senderRole === 'ADMIN') {
      nextStatus = 'WAITING_FOR_CUSTOMER';
    }

    await this.prisma.supportTicket.update({
      where: { id: ticketId },
      data: { status: nextStatus },
    });

    return message;
  }

  async getAdminTicketQueue(filters: {
    status?: string;
    category?: string;
    priority?: string;
    organizationId?: string;
    skip?: number;
    take?: number;
  }) {
    const where: any = {
      ...(filters.status ? { status: filters.status } : {}),
      ...(filters.category ? { category: filters.category } : {}),
      ...(filters.priority ? { priority: filters.priority } : {}),
      ...(filters.organizationId ? { organizationId: filters.organizationId } : {}),
    };

    const [items, total] = await Promise.all([
      this.prisma.supportTicket.findMany({
        where,
        include: {
          user: { select: { id: true, fullName: true, email: true } },
          booking: { include: { facility: { include: { venue: true } } } },
          dispute: true,
        },
        orderBy: [{ priority: 'desc' }, { createdAt: 'desc' }],
        skip: filters.skip,
        take: filters.take,
      }),
      this.prisma.supportTicket.count({ where }),
    ]);

    return { items, total };
  }

  async updateTicketStatus(agentId: string, ticketId: string, status: string, notes?: string) {
    const ticket = await this.prisma.supportTicket.findUnique({ where: { id: ticketId } });
    if (!ticket) throw new NotFoundException('Support ticket not found');

    const isClosed = status === 'RESOLVED' || status === 'CLOSED';

    const updated = await this.prisma.supportTicket.update({
      where: { id: ticketId },
      data: {
        status,
        assignedAgentId: agentId,
        resolutionNotes: notes || ticket.resolutionNotes,
        ...(isClosed ? { closedAt: new Date() } : {}),
      },
    });

    await this.auditService.record({
      userId: agentId,
      action: 'support:ticket_status_updated',
      resource: 'support_ticket',
      resourceId: ticketId,
      payload: { previousStatus: ticket.status, newStatus: status, notes },
      status: 'success',
    });

    return updated;
  }
}
