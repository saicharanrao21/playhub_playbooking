import { Test, TestingModule } from '@nestjs/testing';
import { CacheService } from './cache.service';
import { RedisService } from './redis.service';

describe('CacheService (Fallback & Resilience)', () => {
  let cacheService: CacheService;

  const mockRedisService = {
    getClient: jest.fn(),
    formatKey: jest.fn((ns, key) => `playhub:${ns}:${key}`),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CacheService,
        { provide: RedisService, useValue: mockRedisService },
      ],
    }).compile();

    cacheService = module.get<CacheService>(CacheService);
  });

  it('should fall back to database fetcher when Redis is disconnected', async () => {
    mockRedisService.getClient.mockReturnValue(null);

    const dbFetcher = jest.fn().mockResolvedValue({ id: 'venue-101', name: 'Gachibowli Arena' });

    const result = await cacheService.getOrSet('venue-101', dbFetcher, 300);

    expect(dbFetcher).toHaveBeenCalledTimes(1);
    expect(result).toEqual({ id: 'venue-101', name: 'Gachibowli Arena' });
  });

  it('should return cached value if present in Redis', async () => {
    const mockClient = {
      get: jest.fn().mockResolvedValue(JSON.stringify({ id: 'venue-101', name: 'Gachibowli Arena' })),
    };
    mockRedisService.getClient.mockReturnValue(mockClient);

    const dbFetcher = jest.fn();

    const result = await cacheService.getOrSet('venue-101', dbFetcher, 300);

    expect(result).toEqual({ id: 'venue-101', name: 'Gachibowli Arena' });
    expect(dbFetcher).not.toHaveBeenCalled();
  });
});
