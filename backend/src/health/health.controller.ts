import { Controller, Get, Optional } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { PrismaService } from '../prisma/prisma.service';
import { RedisService } from '../redis/redis.service';
import { QueueService } from '../queues/queue.service';

@ApiTags('health')
@Controller('health')
export class HealthController {
  constructor(
    private prisma: PrismaService,
    @Optional() private redisService?: RedisService,
    @Optional() private queueService?: QueueService,
  ) {}

  @Get()
  @ApiOperation({ summary: 'Check if the service is alive' })
  check() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      service: 'playhub-backend',
    };
  }

  @Get('readiness')
  @ApiOperation({ summary: 'Check if the service is ready to handle requests' })
  async readiness() {
    let dbStatus = 'disconnected';
    let redisStatus = 'disconnected';
    let isReady = false;

    try {
      await this.prisma.$queryRaw`SELECT 1`;
      dbStatus = 'connected';
      isReady = true;
    } catch (_) {
      dbStatus = 'disconnected';
    }

    if (this.redisService) {
      const redisHealthy = await this.redisService.isHealthy();
      redisStatus = redisHealthy ? 'connected' : 'disconnected';
    }

    let queueStats = [];
    if (this.queueService) {
      queueStats = await this.queueService.getQueueHealth();
    }

    return {
      status: isReady ? 'ready' : 'not_ready',
      database: dbStatus,
      redis: redisStatus,
      queues: queueStats,
    };
  }
}
