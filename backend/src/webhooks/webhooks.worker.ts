import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Worker, Job } from 'bullmq';
import { WebhooksService } from './webhooks.service';

@Injectable()
export class WebhookWorker implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(WebhookWorker.name);
  private worker: Worker | null = null;

  constructor(
    private readonly configService: ConfigService,
    private readonly webhooksService: WebhooksService,
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
        'webhooks',
        async (job: Job) => {
          this.logger.log(`Processing webhook job [${job.id}] for event: ${job.data.webhookEventId}`);
          await this.webhooksService.processWebhookEvent(job.data.webhookEventId);
          return { status: 'PROCESSED', jobId: job.id };
        },
        {
          connection,
          prefix: 'playhub:queue',
          concurrency: 5,
        },
      );

      this.worker.on('completed', (job) => {
        this.logger.log(`Webhook job [${job.id}] completed successfully`);
      });

      this.worker.on('failed', (job, err) => {
        this.logger.error(`Webhook job [${job?.id}] failed: ${err.message}`, err.stack);
      });
    } catch (e) {
      this.logger.warn(`Failed to initialize WebhookWorker: ${e.message}`);
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
