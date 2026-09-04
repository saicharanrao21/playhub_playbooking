import { Injectable, Logger } from '@nestjs/common';
import { RedisService } from './redis.service';

@Injectable()
export class CacheService {
  private readonly logger = new Logger(CacheService.name);
  private readonly defaultTtlSeconds = 300; // 5 minutes default TTL

  constructor(private readonly redisService: RedisService) {}

  async get<T>(key: string): Promise<T | null> {
    try {
      const client = this.redisService.getClient();
      if (!client) return null;

      const formattedKey = this.redisService.formatKey('cache', key);
      const raw = await client.get(formattedKey);
      if (!raw) return null;

      return JSON.parse(raw) as T;
    } catch (e) {
      this.logger.warn(`Cache get failed for key [${key}]: ${e.message}`);
      return null;
    }
  }

  async set<T>(key: string, value: T, ttlSeconds: number = this.defaultTtlSeconds): Promise<boolean> {
    try {
      const client = this.redisService.getClient();
      if (!client) return false;

      const formattedKey = this.redisService.formatKey('cache', key);
      const serialized = JSON.stringify(value);

      if (ttlSeconds > 0) {
        await client.set(formattedKey, serialized, 'EX', ttlSeconds);
      } else {
        await client.set(formattedKey, serialized);
      }
      return true;
    } catch (e) {
      this.logger.warn(`Cache set failed for key [${key}]: ${e.message}`);
      return false;
    }
  }

  async del(key: string): Promise<boolean> {
    try {
      const client = this.redisService.getClient();
      if (!client) return false;

      const formattedKey = this.redisService.formatKey('cache', key);
      await client.del(formattedKey);
      return true;
    } catch (e) {
      this.logger.warn(`Cache del failed for key [${key}]: ${e.message}`);
      return false;
    }
  }

  async delPattern(pattern: string): Promise<number> {
    try {
      const client = this.redisService.getClient();
      if (!client) return 0;

      const formattedPattern = this.redisService.formatKey('cache', pattern);
      const keys = await client.keys(formattedPattern);

      if (keys.length === 0) return 0;

      const deleted = await client.del(...keys);
      return deleted;
    } catch (e) {
      this.logger.warn(`Cache delPattern failed for pattern [${pattern}]: ${e.message}`);
      return 0;
    }
  }

  /**
   * Safe Get-or-Set Cache Pattern with automatic database fallback.
   */
  async getOrSet<T>(
    key: string,
    fetcher: () => Promise<T>,
    ttlSeconds: number = this.defaultTtlSeconds,
  ): Promise<T> {
    const cached = await this.get<T>(key);
    if (cached !== null && cached !== undefined) {
      return cached;
    }

    // Execute database fetcher
    const fresh = await fetcher();

    // Cache the fresh result asynchronously
    if (fresh !== null && fresh !== undefined) {
      this.set(key, fresh, ttlSeconds).catch(() => {});
    }

    return fresh;
  }
}
