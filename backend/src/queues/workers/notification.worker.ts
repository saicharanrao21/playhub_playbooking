import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Worker, Job } from 'bullmq';
import { NotificationsService } from '../../notifications/notifications.service';

@Injectable()
export class NotificationWorker implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(NotificationWorker.name);
  private worker: Worker | null = null;

  constructor(
    private readonly configService: ConfigService,
    private readonly notificationsService: NotificationsService,
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
        'notifications',
        async (job: Job) => {
          this.logger.log(`Processing notification job [${job.id}] name: ${job.name}`);
          const payload = job.data;

          // Idempotency: Create notification record
          await this.notificationsService.create({
            organizationId: payload.organizationId,
            userId: payload.userId,
            bookingId: payload.bookingId,
            type: payload.type || 'SYSTEM_ALERT',
            title: payload.title || 'PlayHub Alert',
            message: payload.message || '',
            payload: payload.data || payload,
          });

          return { status: 'DELIVERED', jobId: job.id };
        },
        {
          connection,
          prefix: 'playhub:queue',
          concurrency: 5,
        },
      );

      this.worker.on('completed', (job) => {
        this.logger.log(`Notification job [${job.id}] completed successfully`);
      });

      this.worker.on('failed', (job, err) => {
        this.logger.error(`Notification job [${job?.id}] failed: ${err.message}`, err.stack);
      });
    } catch (e) {
      this.logger.warn(`Failed to initialize NotificationWorker: ${e.message}`);
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
