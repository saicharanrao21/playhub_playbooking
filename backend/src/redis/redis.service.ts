import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis, { RedisOptions } from 'ioredis';

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  private client: Redis | null = null;
  private isConnected = false;

  constructor(private readonly configService: ConfigService) {}

  async onModuleInit() {
    this.initClient();
  }

  async onModuleDestroy() {
    if (this.client) {
      this.logger.log('Closing Redis connection...');
      await this.client.quit();
      this.client = null;
      this.isConnected = false;
    }
  }

  private initClient() {
    const redisUrl = this.configService.get<string>('REDIS_URL') || 'redis://localhost:6379';

    const options: RedisOptions = {
      maxRetriesPerRequest: 3,
      enableReadyCheck: true,
      lazyConnect: true,
      retryStrategy: (times) => {
        if (times > 5) {
          this.logger.warn(`Redis connection retry limit reached (${times} attempts). Falling back to database.`);
          return null; // Stop retrying automatically to avoid blocking
        }
        const delay = Math.min(times * 200, 2000);
        return delay;
      },
    };

    try {
      this.client = new Redis(redisUrl, options);

      this.client.on('connect', () => {
        this.logger.log(`Connected to Redis at ${redisUrl.replace(/\/\/[^@]+@/, '//***@')}`);
        this.isConnected = true;
      });

      this.client.on('error', (err) => {
        this.logger.warn(`Redis Client Error: ${err.message}`);
        this.isConnected = false;
      });

      // Attempt non-blocking initial connection
      this.client.connect().catch((err) => {
        this.logger.warn(`Redis lazy connection failed: ${err.message}. Operating in fallback mode.`);
        this.isConnected = false;
      });
    } catch (e) {
      this.logger.warn(`Failed to initialize Redis client: ${e.message}`);
      this.client = null;
      this.isConnected = false;
    }
  }

  getClient(): Redis | null {
    return this.client;
  }

  async isHealthy(): Promise<boolean> {
    if (!this.client || !this.isConnected) return false;
    try {
      const pong = await this.client.ping();
      return pong === 'PONG';
    } catch (_) {
      return false;
    }
  }

  /**
   * Helper to construct namespaced keys.
   */
  formatKey(namespace: 'cache' | 'lock' | 'queue', key: string): string {
    return `playhub:${namespace}:${key}`;
  }
}
