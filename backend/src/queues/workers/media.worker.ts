import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Worker, Job } from 'bullmq';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class MediaWorker implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(MediaWorker.name);
  private worker: Worker | null = null;

  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
  ) {}

  async onModuleInit() {
    this.initWorker();
  }

  async onModuleDestroy() {
    if (this.worker) {
      await this.worker.close();
      this.worker = null;
    }
  }

  private initWorker() {
    const redisUrl = this.configService.get<string>('REDIS_URL') || 'redis://localhost:6379';
    const connection = this.parseRedisUrl(redisUrl);

    try {
      this.worker = new Worker(
        'media',
        async (job: Job) => {
          this.logger.log(`Processing media job [${job.id}] for mediaId: ${job.data.mediaId}`);
          const { mediaId } = job.data;

          const media = await this.prisma.media.findUnique({ where: { id: mediaId } });
          if (!media) return { status: 'NOT_FOUND' };

          // Update status to READY
          await this.prisma.media.update({
            where: { id: mediaId },
            data: { status: 'READY' },
          });

          return { status: 'READY', mediaId };
        },
        {
          connection,
          prefix: 'playhub:queue',
          concurrency: 3,
        },
      );

      this.worker.on('completed', (job) => {
        this.logger.log(`Media processing job [${job.id}] completed`);
      });

      this.worker.on('failed', (job, err) => {
        this.logger.error(`Media processing job [${job?.id}] failed: ${err.message}`, err.stack);
      });
    } catch (e) {
      this.logger.warn(`Failed to initialize MediaWorker: ${e.message}`);
    }
  }

  private parseRedisUrl(url: string) {
    try {
      const parsed = new URL(url);
      return {
        host: parsed.hostname || 'localhost',
        port: parseInt(parsed.port || '6379', 10),
        password: parsed.password || undefined,
      };
    } catch (_) {
      return { host: 'localhost', port: 6379 };
    }
  }
}
