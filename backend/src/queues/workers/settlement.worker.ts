import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Worker, Job } from 'bullmq';
import { SettlementService } from '../../finance/settlement.service';

@Injectable()
export class SettlementWorker implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(SettlementWorker.name);
  private worker: Worker | null = null;

  constructor(
    private readonly configService: ConfigService,
    private readonly settlementService: SettlementService,
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
        'settlement',
        async (job: Job) => {
          this.logger.log(`Processing settlement job [${job.id}] for org: ${job.data.organizationId}`);
          const settlement = await this.settlementService.createSettlement(job.data);
          return { status: 'FINALIZED', settlementId: settlement.id };
        },
        {
          connection,
          prefix: 'playhub:queue',
          concurrency: 2,
        },
      );

      this.worker.on('failed', (job, err) => {
        this.logger.error(`Settlement job [${job?.id}] failed: ${err.message}`, err.stack);
      });
    } catch (e) {
      this.logger.warn(`Failed to initialize SettlementWorker: ${e.message}`);
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
