import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Worker, Job } from 'bullmq';
import { ReportsService } from '../../analytics/reports.service';

@Injectable()
export class ReportWorker implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(ReportWorker.name);
  private worker: Worker | null = null;

  constructor(
    private readonly configService: ConfigService,
    private readonly reportsService: ReportsService,
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
        'reports',
        async (job: Job) => {
          this.logger.log(`Processing report job [${job.id}] for reportJobId: ${job.data.reportJobId}`);
          await this.reportsService.processPdfReportJob(job.data.reportJobId);
          return { status: 'READY', reportJobId: job.data.reportJobId };
        },
        {
          connection,
          prefix: 'playhub:queue',
          concurrency: 2,
        },
      );

      this.worker.on('completed', (job) => {
        this.logger.log(`Report processing job [${job.id}] completed`);
      });

      this.worker.on('failed', (job, err) => {
        this.logger.error(`Report processing job [${job?.id}] failed: ${err.message}`, err.stack);
      });
    } catch (e) {
      this.logger.warn(`Failed to initialize ReportWorker: ${e.message}`);
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
