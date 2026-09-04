import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Worker, Job } from 'bullmq';
import { ReconciliationService } from '../../finance/reconciliation.service';

@Injectable()
export class ReconciliationWorker implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(ReconciliationWorker.name);
  private worker: Worker | null = null;

  constructor(
    private readonly configService: ConfigService,
    private readonly reconciliationService: ReconciliationService,
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
        'reconciliation',
        async (job: Job) => {
          this.logger.log(`Executing scheduled reconciliation job [${job.id}]`);
          const query = job.data || {};

          const report = await this.reconciliationService.runReconciliation(query);

          this.logger.log(
            `Reconciliation job [${job.id}] completed: Status=${report.reconciliationStatus}, Checked=${report.totalChecked}, Discrepancies=${report.discrepancyCount}`,
          );

          return report;
        },
        {
          connection,
          prefix: 'playhub:queue',
          concurrency: 1,
        },
      );

      this.worker.on('failed', (job, err) => {
        this.logger.error(`Reconciliation job [${job?.id}] failed: ${err.message}`, err.stack);
      });
    } catch (e) {
      this.logger.warn(`Failed to initialize ReconciliationWorker: ${e.message}`);
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
