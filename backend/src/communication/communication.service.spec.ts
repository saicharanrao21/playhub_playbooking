import { Test, TestingModule } from '@nestjs/testing';
import { CommunicationService } from './communication.service';
import { PrismaService } from '../prisma/prisma.service';
import { TemplateRegistry } from './template.registry';
import {
  EMAIL_PROVIDER,
  SMS_PROVIDER,
  WHATSAPP_PROVIDER,
  PUSH_PROVIDER
} from './interfaces/provider-tokens';
import { ConfigService } from '@nestjs/config';
import { CommunicationCategory, CommunicationChannel, CommunicationStatus, Prisma } from '@prisma/client';
import { ForbiddenException, NotFoundException } from '@nestjs/common';

describe('CommunicationService', () => {
  let service: CommunicationService;
  let prisma: PrismaService;
  let emailProvider: any;

  beforeEach(async () => {
    emailProvider = {
      send: jest.fn().mockResolvedValue({ success: true }),
      getName: () => 'RESEND',
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CommunicationService,
        TemplateRegistry,
        {
          provide: PrismaService,
          useValue: {
            communicationPreference: {
              findMany: jest.fn().mockResolvedValue([]),
              upsert: jest.fn(),
            },
            communicationLog: {
              create: jest.fn().mockResolvedValue({ id: 'log-1' }),
              update: jest.fn().mockResolvedValue({}),
            },
            user: {
              findUnique: jest.fn().mockResolvedValue({ id: 'user-1', email: 'test@example.com' }),
            },
            device: {
              findUnique: jest.fn(),
              update: jest.fn(),
              upsert: jest.fn(),
            },
          },
        },
        { provide: EMAIL_PROVIDER, useValue: emailProvider },
        { provide: SMS_PROVIDER, useValue: { getName: () => 'MOCK_SMS', send: jest.fn() } },
        { provide: WHATSAPP_PROVIDER, useValue: { getName: () => 'MOCK_WA', send: jest.fn() } },
        { provide: PUSH_PROVIDER, useValue: { getName: () => 'MOCK_PUSH', send: jest.fn() } },
        {
          provide: ConfigService,
          useValue: { get: jest.fn().mockReturnValue('development') },
        },
      ],
    }).compile();

    service = module.get<CommunicationService>(CommunicationService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  describe('unregisterDevice', () => {
    it('should unregister own device', async () => {
      jest.spyOn(prisma.device, 'findUnique').mockResolvedValue({ userId: 'user-1', token: 't1' } as any);
      await service.unregisterDevice('user-1', 't1');
      expect(prisma.device.update).toHaveBeenCalledWith({
        where: { token: 't1' },
        data: { isActive: false },
      });
    });

    it('should throw ForbiddenException if device belongs to another user', async () => {
      jest.spyOn(prisma.device, 'findUnique').mockResolvedValue({ userId: 'user-2', token: 't1' } as any);
      await expect(service.unregisterDevice('user-1', 't1')).rejects.toThrow(ForbiddenException);
    });

    it('should throw NotFoundException if device not found', async () => {
      jest.spyOn(prisma.device, 'findUnique').mockResolvedValue(null);
      await expect(service.unregisterDevice('user-1', 't1')).rejects.toThrow(NotFoundException);
    });
  });

  describe('idempotency', () => {
    it('should block duplicate events using idempotencyKey', async () => {
      const error = new Prisma.PrismaClientKnownRequestError('Conflict', { code: 'P2002', clientVersion: '5.x' });
      jest.spyOn(prisma.communicationLog, 'create').mockRejectedValue(error);

      await service.sendNotification({
        userId: 'user-1',
        type: 'TEST',
        category: CommunicationCategory.TRANSACTIONAL,
        variables: {},
        idempotencyKey: 'key-1',
        channels: [CommunicationChannel.EMAIL]
      });

      expect(emailProvider.send).not.toHaveBeenCalled();
    });
  });

  describe('Communication Policy', () => {
    it('should bypass preferences for SECURITY category', async () => {
      jest.spyOn(prisma.communicationPreference, 'findMany').mockResolvedValue([
        { channel: CommunicationChannel.EMAIL, isEnabled: false } as any
      ]);

      await service.sendNotification({
        userId: 'user-1',
        type: 'SECURITY_ALERT',
        category: CommunicationCategory.SECURITY,
        variables: {},
        channels: [CommunicationChannel.EMAIL]
      });

      expect(emailProvider.send).toHaveBeenCalled();
    });

    it('should respect preferences for MARKETING category', async () => {
      jest.spyOn(prisma.communicationPreference, 'findMany').mockResolvedValue([
        { channel: CommunicationChannel.EMAIL, isEnabled: false } as any
      ]);

      await service.sendNotification({
        userId: 'user-1',
        type: 'OFFER',
        category: CommunicationCategory.MARKETING,
        variables: {},
        channels: [CommunicationChannel.EMAIL]
      });

      expect(emailProvider.send).not.toHaveBeenCalled();
    });
  });
});
