import { Module, Global } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { RedisService } from './redis.service';
import { CacheService } from './cache.service';
import { LockService } from './lock.service';

@Global()
@Module({
  imports: [ConfigModule],
  providers: [RedisService, CacheService, LockService],
  exports: [RedisService, CacheService, LockService],
})
export class RedisModule {}
