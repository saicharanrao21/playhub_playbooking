import { Test, TestingModule } from '@nestjs/testing';
import { QueueService } from './queue.service';
import { ConfigService } from '@nestjs/config';

describe('QueueService (BullMQ Infrastructure)', () => {
  let queueService: QueueService;

  const mockConfigService = {
    get: jest.fn().mockReturnValue('redis://localhost:6379'),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        QueueService,
        { provide: ConfigService, useValue: mockConfigService },
      ],
    }).compile();

    queueService = module.get<QueueService>(QueueService);
  });

  it('should be defined', () => {
    expect(queueService).toBeDefined();
  });

  it('should return health stats array for queues', async () => {
    const health = await queueService.getQueueHealth();
    expect(Array.isArray(health)).toBe(true);
  });
});
