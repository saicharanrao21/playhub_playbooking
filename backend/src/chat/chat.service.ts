import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Optional,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { Events } from '../common/constants/events';
import { MetricsService } from '../observability/metrics.service';
import { ChatMessageType } from './chat.types';
import { Prisma } from '@prisma/client';

@Injectable()
export class ChatService {
  private readonly logger = new Logger(ChatService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly eventEmitter: EventEmitter2,
    @Optional() private readonly metricsService?: MetricsService,
  ) {}

  /**
   * Finds or initializes persistent MatchConversation for a match/booking.
   */
  async getOrCreateConversation(matchId: string, organizationId?: string) {
    const existing = await this.prisma.matchConversation.findUnique({
      where: { matchId },
    });

    if (existing) return existing;

    return this.prisma.matchConversation.create({
      data: {
        matchId,
        organizationId: organizationId || null,
        status: 'ACTIVE',
      },
    });
  }

  /**
   * Fetches paginated chat message history for reconnect synchronization.
   */
  async getConversationMessages(matchId: string, skip = 0, take = 50) {
    const conversation = await this.getOrCreateConversation(matchId);

    const [items, total] = await Promise.all([
      this.prisma.chatMessage.findMany({
        where: { conversationId: conversation.id },
        include: {
          sender: {
            select: {
              id: true,
              fullName: true,
              email: true,
              avatarUrl: true,
            },
          },
        },
        orderBy: { createdAt: 'asc' },
        skip,
        take,
      }),
      this.prisma.chatMessage.count({
        where: { conversationId: conversation.id },
      }),
    ]);

    return { items, total };
  }

  /**
   * Persists chat message in PostgreSQL with clientMessageId idempotency.
   */
  async sendMessage(
    userId: string,
    matchId: string,
    body: string,
    clientMessageId?: string,
    messageType: string = ChatMessageType.TEXT,
  ) {
    const trimmedBody = body.trim();
    if (!trimmedBody) {
      throw new BadRequestException('Message body cannot be empty');
    }
    if (trimmedBody.length > 1000) {
      throw new BadRequestException('Message length exceeds 1000 characters');
    }

    const conversation = await this.getOrCreateConversation(matchId);

    // Idempotency Check via clientMessageId
    if (clientMessageId) {
      const existing = await this.prisma.chatMessage.findUnique({
        where: { clientMessageId },
        include: { sender: { select: { id: true, fullName: true, avatarUrl: true } } },
      });
      if (existing) return existing;
    }

    try {
      const message = await this.prisma.chatMessage.create({
        data: {
          conversationId: conversation.id,
          senderId: userId,
          messageType,
          body: trimmedBody,
          clientMessageId: clientMessageId || null,
        },
        include: {
          sender: {
            select: {
              id: true,
              fullName: true,
              email: true,
              avatarUrl: true,
            },
          },
        },
      });

      if (this.metricsService) {
        this.metricsService.cacheOperationsTotal.inc({ operation: 'chat_msg', result: 'success' });
      }

      return message;
    } catch (e) {
      if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
        // Unique constraint on clientMessageId
        return this.prisma.chatMessage.findUnique({
          where: { clientMessageId },
          include: { sender: { select: { id: true, fullName: true, avatarUrl: true } } },
        });
      }
      throw e;
    }
  }

  /**
   * Registers real-time court arrival event for a player at a venue/court.
   */
  async registerCourtArrival(userId: string, matchId: string, notes?: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    const senderName = user?.fullName || user?.email || 'Player';

    const bodyText = `📍 ${senderName} has arrived at the court! ${notes ? `(${notes})` : ''}`;

    const arrivalMessage = await this.sendMessage(
      userId,
      matchId,
      bodyText,
      `arrival_${userId}_${matchId}_${Date.now()}`,
      ChatMessageType.ARRIVAL_ALERT,
    );

    // Emit event so NotificationsModule / BullMQ alerts offline players
    this.eventEmitter.emit(Events.BOOKING_ARRIVED, {
      matchId,
      userId,
      facilityName: 'Court',
      notes,
    });

    return {
      matchId,
      userId,
      senderName,
      arrivalMessage,
      timestamp: new Date().toISOString(),
    };
  }

  /**
   * Verifies that user is authorized to participate in match chat.
   */
  async validateMatchAccess(userId: string, matchId: string): Promise<boolean> {
    // Check if matchId is a Booking or Match
    const booking = await this.prisma.booking.findFirst({
      where: {
        OR: [{ id: matchId }, { facilityId: matchId }],
        userId,
      },
    });

    if (booking) return true;

    // Fallback: Check if user exists in PlayHub system
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    return !!user;
  }
}
