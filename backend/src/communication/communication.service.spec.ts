import { Test, TestingModule } from '@nestjs/testing';
import { CommunicationService } from './communication.service';
import { PrismaService } from '../prisma/prisma.service';
import { TemplateRegistry } from './template.registry';
import { ResendEmailProvider } from './providers/resend-email.provider';
import { MockSmsProvider } from './providers/mock-sms.provider';
import { MockWhatsAppProvider } from './providers/mock-whatsapp.provider';
import { MockPushProvider } from './providers/mock-push.provider';
import { ConfigService } from '@nestjs/config';

describe('CommunicationService', () => {
  let service: CommunicationService;
  let prisma: PrismaService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CommunicationService,
        TemplateRegistry,
        {
          provide: PrismaService,
          useValue: {
            communicationPreference: {
              findMany: jest.fn().mockResolvedValue([]),
            },
            communicationLog: {
              create: jest.fn().mockResolvedValue({ id: 'log-1' }),
              update: jest.fn().mockResolvedValue({}),
            },
            user: {
              findUnique: jest.fn().mockResolvedValue({ id: 'user-1', email: 'test@example.com' }),
            },
          },
        },
        {
          provide: ResendEmailProvider,
          useValue: {
            send: jest.fn().mockResolvedValue({ success: true }),
            getName: () => 'RESEND',
          },
        },
        {
          provide: MockSmsProvider,
          useValue: {
            send: jest.fn().mockResolvedValue({ success: true }),
            getName: () => 'MOCK_SMS',
          },
        },
        {
          provide: MockWhatsAppProvider,
          useValue: {
            send: jest.fn().mockResolvedValue({ success: true }),
            getName: () => 'MOCK_WHATSAPP',
          },
        },
        {
          provide: MockPushProvider,
          useValue: {
            send: jest.fn().mockResolvedValue({ success: true }),
            getName: () => 'MOCK_PUSH',
          },
        },
        {
          provide: ConfigService,
          useValue: {
            get: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<CommunicationService>(CommunicationService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
