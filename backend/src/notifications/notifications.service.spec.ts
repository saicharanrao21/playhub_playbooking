import { Test, TestingModule } from '@nestjs/testing';
import { NotificationsService } from './notifications.service';
import { PrismaService } from '../prisma/prisma.service';
import { NotificationType } from '@prisma/client';

describe('NotificationsService', () => {
  let service: NotificationsService;
  let prisma: PrismaService;

  const mockPrisma = {
    notification: {
      create: jest.fn(),
      findMany: jest.fn(),
      findFirst: jest.fn(),
      update: jest.fn(),
      updateMany: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        NotificationsService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<NotificationsService>(NotificationsService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should create a notification', async () => {
    const data = {
      organizationId: 'org1',
      userId: 'u1',
      type: NotificationType.BOOKING_CONFIRMED,
      title: 'Title',
      message: 'Msg',
    };
    mockPrisma.notification.create.mockResolvedValue({ id: 'n1', ...data });

    const result = await service.create(data);
    expect(result.id).toBe('n1');
    expect(mockPrisma.notification.create).toHaveBeenCalled();
  });

  it('should find all notifications for a user', async () => {
    mockPrisma.notification.findMany.mockResolvedValue([{ id: 'n1' }]);
    const result = await service.findAll('org1', 'u1');
    expect(result).toHaveLength(1);
    expect(mockPrisma.notification.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { organizationId: 'org1', userId: 'u1' } }),
    );
  });
});
