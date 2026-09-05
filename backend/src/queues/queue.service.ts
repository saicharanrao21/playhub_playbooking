import { Injectable, Logger, OnModuleInit, OnModuleDestroy, Optional } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Queue, JobsOptions } from 'bullmq';
import { MetricsService } from '../observability/metrics.service';

export interface QueueHealthStats {
  queueName: string;
  active: number;
  waiting: number;
  completed: number;
  failed: number;
  delayed: number;
}

@Injectable()
export class QueueService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(QueueService.name);
  private queues: Map<string, Queue> = new Map();

  constructor(
    private readonly configService: ConfigService,
    @Optional() private readonly metricsService?: MetricsService,
  ) {}

  async onModuleInit() {
    this.initQueues();
  }

  async onModuleDestroy() {
    this.logger.log('Closing BullMQ queues...');
    for (const [name, queue] of this.queues.entries()) {
      await queue.close();
    }
    this.queues.clear();
  }

  private initQueues() {
    const redisUrl = this.configService.get<string>('REDIS_URL') || 'redis://localhost:6379';
    const connection = this.parseRedisUrl(redisUrl);

    const queueNames = ['notifications', 'finance', 'reconciliation', 'settlement', 'webhooks', 'media'];

    const defaultJobOptions: JobsOptions = {
      attempts: 3,
      backoff: {
        type: 'exponential',
        delay: 1000,
      },
      removeOnComplete: { count: 1000 },
      removeOnFail: { count: 5000 },
    };

    for (const name of queueNames) {
      try {
        const queue = new Queue(name, {
          connection,
          prefix: 'playhub:queue',
          defaultJobOptions,
        });

        this.queues.set(name, queue);
        this.logger.log(`BullMQ Queue [${name}] initialized`);
      } catch (e) {
        this.logger.warn(`Failed to initialize BullMQ queue [${name}]: ${e.message}`);
      }
    }

    // Schedule Nightly Reconciliation Repeatable Job
    this.scheduleNightlyReconciliation().catch((err) => {
      this.logger.warn(`Failed to schedule nightly reconciliation job: ${err.message}`);
    });
  }

  /**
   * Schedules a repeatable 24-hour reconciliation job in BullMQ.
   */
  async scheduleNightlyReconciliation() {
    const queue = this.queues.get('reconciliation');
    if (!queue) return;

    const todayStr = new Date().toISOString().split('T')[0];
    await queue.add(
      'nightly-reconciliation',
      { date: todayStr, triggeredBy: 'SCHEDULED_CRON' },
      {
        jobId: `reconciliation_nightly_${todayStr}`,
        repeat: {
          pattern: '0 0 * * *',
        },
      } as any,
    );
    this.logger.log('Nightly reconciliation scheduled job registered.');
  }

  async addNotificationJob(name: string, payload: any, opts?: JobsOptions) {
    return this.addJob('notifications', name, payload, opts);
  }

  async addFinanceJob(name: string, payload: any, opts?: JobsOptions) {
    return this.addJob('finance', name, payload, opts);
  }

  async addReconciliationJob(name: string, payload: any, opts?: JobsOptions) {
    return this.addJob('reconciliation', name, payload, opts);
  }

  async addSettlementJob(name: string, payload: any, opts?: JobsOptions) {
    return this.addJob('settlement', name, payload, opts);
  }

  async addWebhookJob(name: string, payload: any, opts?: JobsOptions) {
    return this.addJob('webhooks', name, payload, opts);
  }

  async addMediaJob(name: string, payload: any, opts?: JobsOptions) {
    return this.addJob('media', name, payload, opts);
  }

  private async addJob(queueName: string, name: string, payload: any, opts?: JobsOptions) {
    const queue = this.queues.get(queueName);
    if (!queue) {
      this.logger.warn(`Queue [${queueName}] not available for job [${name}].`);
      return null;
    }

    try {
      const job = await queue.add(name, payload, opts);
      if (this.metricsService) {
        this.metricsService.queueJobsTotal.inc({ queue: queueName, status: 'added' });
      }
      return job;
    } catch (e) {
      this.logger.error(`Failed to add job [${name}] to queue [${queueName}]: ${e.message}`);
      return null;
    }
  }

  async getQueueHealth(): Promise<QueueHealthStats[]> {
    const stats: QueueHealthStats[] = [];

    for (const [name, queue] of this.queues.entries()) {
      try {
        const [active, waiting, completed, failed, delayed] = await Promise.all([
          queue.getActiveCount(),
          queue.getWaitingCount(),
          queue.getCompletedCount(),
          queue.getFailedCount(),
          queue.getDelayedCount(),
        ]);

        stats.push({
          queueName: name,
          active,
          waiting,
          completed,
          failed,
          delayed,
        });
      } catch (e) {
        stats.push({
          queueName: name,
          active: 0,
          waiting: 0,
          completed: 0,
          failed: 0,
          delayed: 0,
        });
      }
    }

    return stats;
  }

  async retryFailedJobs(queueName: string): Promise<number> {
    const queue = this.queues.get(queueName);
    if (!queue) return 0;

    const failed = await queue.getFailed();
    let retried = 0;

    for (const job of failed) {
      await job.retry();
      retried++;
    }

    return retried;
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
