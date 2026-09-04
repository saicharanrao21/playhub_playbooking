import { Injectable, Logger } from '@nestjs/common';
import { RedisService } from './redis.service';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class LockService {
  private readonly logger = new Logger(LockService.name);
  private readonly defaultLockTtlMs = 10000; // 10 seconds default

  constructor(private readonly redisService: RedisService) {}

  /**
   * Tries to acquire an atomic distributed lock in Redis.
   * Returns unique lock token if acquired, or null if lock acquisition failed.
   */
  async acquireLock(lockKey: string, ttlMs: number = this.defaultLockTtlMs): Promise<string | null> {
    try {
      const client = this.redisService.getClient();
      if (!client) return null;

      const formattedKey = this.redisService.formatKey('lock', lockKey);
      const lockToken = uuidv4();

      // SET key token NX PX ttlMs
      const result = await client.set(formattedKey, lockToken, 'PX', ttlMs, 'NX');

      if (result === 'OK') {
        return lockToken;
      }

      return null;
    } catch (e) {
      this.logger.warn(`Distributed lock acquire failed for [${lockKey}]: ${e.message}`);
      return null;
    }
  }

  /**
   * Safely releases a distributed lock using Lua script to verify lock ownership token.
   */
  async releaseLock(lockKey: string, lockToken: string): Promise<boolean> {
    try {
      const client = this.redisService.getClient();
      if (!client) return false;

      const formattedKey = this.redisService.formatKey('lock', lockKey);

      // Atomic release Lua script
      const luaScript = `
        if redis.call("get", KEYS[1]) == ARGV[1] then
          return redis.call("del", KEYS[1])
        else
          return 0
        end
      `;

      const result = await client.eval(luaScript, 1, formattedKey, lockToken);
      return result === 1;
    } catch (e) {
      this.logger.warn(`Distributed lock release failed for [${lockKey}]: ${e.message}`);
      return false;
    }
  }
}
