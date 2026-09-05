import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server } from 'socket.io';
import { Logger, UseGuards, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { ChatService } from './chat.service';
import { AuthenticatedSocket, ChatMessageType } from './chat.types';

@WebSocketGateway({
  cors: { origin: '*' },
  namespace: 'chat',
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  private readonly logger = new Logger(ChatGateway.name);

  constructor(
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    private readonly chatService: ChatService,
  ) {}

  async handleConnection(client: AuthenticatedSocket) {
    try {
      // Extract JWT from handshake auth token or Authorization header
      const token =
        client.handshake.auth?.token ||
        client.handshake.headers?.authorization?.replace('Bearer ', '');

      if (!token) {
        this.logger.warn(`Disconnecting unauthenticated socket [${client.id}]`);
        client.disconnect(true);
        return;
      }

      const secret = this.configService.get<string>('JWT_ACCESS_SECRET');
      const payload = this.jwtService.verify(token, { secret });

      client.data = {
        user: {
          userId: payload.sub || payload.userId,
          email: payload.email,
          roles: payload.roles || [],
          permissions: payload.permissions || [],
          isPlatformAdmin: !!payload.isPlatformAdmin,
        },
      };

      // Join user's personal room e.g. user:{userId}
      const userRoom = `user:${client.data.user.userId}`;
      await client.join(userRoom);

      this.logger.log(`Socket [${client.id}] authenticated for user [${client.data.user.userId}]`);
    } catch (e) {
      this.logger.warn(`Socket authentication failed [${client.id}]: ${e.message}`);
      client.disconnect(true);
    }
  }

  handleDisconnect(client: AuthenticatedSocket) {
    this.logger.log(`Socket [${client.id}] disconnected`);
  }

  @SubscribeMessage('joinMatchRoom')
  async handleJoinMatchRoom(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { matchId: string },
  ) {
    const userId = client.data?.user?.userId;
    if (!userId || !data?.matchId) {
      return { event: 'error', message: 'Unauthorized or missing matchId' };
    }

    const hasAccess = await this.chatService.validateMatchAccess(userId, data.matchId);
    if (!hasAccess) {
      this.logger.warn(`User [${userId}] denied access to match room [${data.matchId}]`);
      return { event: 'error', message: 'Unauthorized access to match room' };
    }

    const room = `match:${data.matchId}`;
    await client.join(room);

    this.logger.log(`User [${userId}] joined room [${room}]`);
    return { event: 'joinedRoom', room, matchId: data.matchId };
  }

  @SubscribeMessage('leaveMatchRoom')
  async handleLeaveMatchRoom(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { matchId: string },
  ) {
    if (data?.matchId) {
      const room = `match:${data.matchId}`;
      await client.leave(room);
      return { event: 'leftRoom', room };
    }
  }

  @SubscribeMessage('sendMessage')
  async handleSendMessage(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { matchId: string; body: string; clientMessageId?: string; messageType?: string },
  ) {
    const userId = client.data?.user?.userId;
    if (!userId || !data?.matchId || !data?.body) {
      return { event: 'error', message: 'Invalid payload or unauthenticated' };
    }

    const hasAccess = await this.chatService.validateMatchAccess(userId, data.matchId);
    if (!hasAccess) {
      return { event: 'error', message: 'Unauthorized' };
    }

    try {
      const message = await this.chatService.sendMessage(
        userId,
        data.matchId,
        data.body,
        data.clientMessageId,
        data.messageType || ChatMessageType.TEXT,
      );

      // Broadcast to all authorized members in room match:{matchId}
      const room = `match:${data.matchId}`;
      this.server.to(room).emit('newMessage', {
        matchId: data.matchId,
        message,
      });

      return { event: 'messageAck', status: 'delivered', messageId: message.id, clientMessageId: data.clientMessageId };
    } catch (e) {
      this.logger.error(`Failed to send message: ${e.message}`);
      return { event: 'error', message: e.message };
    }
  }

  @SubscribeMessage('courtArrival')
  async handleCourtArrival(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: { matchId: string; notes?: string },
  ) {
    const userId = client.data?.user?.userId;
    if (!userId || !data?.matchId) {
      return { event: 'error', message: 'Invalid payload or unauthenticated' };
    }

    try {
      const result = await this.chatService.registerCourtArrival(userId, data.matchId, data.notes);

      const room = `match:${data.matchId}`;
      this.server.to(room).emit('courtArrival', result);
      this.server.to(room).emit('newMessage', {
        matchId: data.matchId,
        message: result.arrivalMessage,
      });

      return { event: 'arrivalAck', status: 'registered', arrival: result };
    } catch (e) {
      return { event: 'error', message: e.message };
    }
  }
}
