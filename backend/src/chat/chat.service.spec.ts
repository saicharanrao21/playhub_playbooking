import { Test, TestingModule } from '@nestjs/testing';
import { ChatService } from './chat.service';
import { PrismaService } from '../prisma/prisma.service';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { BadRequestException } from '@nestjs/common';

describe('ChatService (Real-Time WebSockets & Message Persistence)', () => {
  let service: ChatService;

  const mockPrisma = {
    matchConversation: {
      findUnique: jest.fn(),
      create: jest.fn(),
    },
    chatMessage: {
      findMany: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
      findUnique: jest.fn(),
    },
    booking: {
      findFirst: jest.fn(),
    },
    user: {
      findUnique: jest.fn(),
    },
  };

  const mockEventEmitter = {
    emit: jest.fn(),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ChatService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: EventEmitter2, useValue: mockEventEmitter },
      ],
    }).compile();

    service = module.get<ChatService>(ChatService);
  });

  it('should persist chat message with clientMessageId idempotency', async () => {
    mockPrisma.matchConversation.findUnique.mockResolvedValue({
      id: 'conv-101',
      matchId: 'match-101',
    });

    mockPrisma.chatMessage.findUnique.mockResolvedValue(null);
    mockPrisma.chatMessage.create.mockResolvedValue({
      id: 'msg-101',
      conversationId: 'conv-101',
      senderId: 'user-101',
      body: 'See you at the court!',
      clientMessageId: 'client_msg_101',
    });

    const result = await service.sendMessage('user-101', 'match-101', 'See you at the court!', 'client_msg_101');

    expect(result.id).toBe('msg-101');
    expect(mockPrisma.chatMessage.create).toHaveBeenCalled();
  });

  it('should reject empty chat messages', async () => {
    await expect(
      service.sendMessage('user-101', 'match-101', '   '),
    ).rejects.toThrow(BadRequestException);
  });

  it('should register court arrival and emit booking.arrived event', async () => {
    mockPrisma.user.findUnique.mockResolvedValue({ id: 'user-101', fullName: 'Aarav' });
    mockPrisma.matchConversation.findUnique.mockResolvedValue({ id: 'conv-101', matchId: 'match-101' });
    mockPrisma.chatMessage.findUnique.mockResolvedValue(null);
    mockPrisma.chatMessage.create.mockResolvedValue({
      id: 'msg-arrival-101',
      body: '📍 Aarav has arrived at the court!',
    });

    const arrival = await service.registerCourtArrival('user-101', 'match-101', 'At Court #2');

    expect(arrival.senderName).toBe('Aarav');
    expect(mockEventEmitter.emit).toHaveBeenCalledWith('booking.arrived', expect.any(Object));
  });
});
