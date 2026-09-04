import { Injectable, Logger, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Worker, Job } from 'bullmq';
import { PayoutService } from '../../finance/payout.service';

@Injectable()
export class PayoutWorker implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PayoutWorker.name);
  private worker: Worker | null = null;

  constructor(
    private readonly configService: ConfigService,
    private readonly payoutService: PayoutService,
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
        'finance',
        async (job: Job) => {
          this.logger.log(`Processing payout job [${job.id}] action: ${job.name}`);
          const { payoutId, providerReference, reason, adminId } = job.data;

          if (job.name === 'complete-payout') {
            return await this.payoutService.completePayout(
              payoutId,
              providerReference || 'BANK_REF_MOCK',
              adminId,
            );
          } else if (job.name === 'fail-payout') {
            return await this.payoutService.failPayout(
              payoutId,
              reason || 'Payout transfer failed',
              adminId,
            );
          }

          return { status: 'IGNORED' };
        },
        {
          connection,
          prefix: 'playhub:queue',
          concurrency: 2,
        },
      );

      this.worker.on('failed', (job, err) => {
        this.logger.error(`Finance payout job [${job?.id}] failed: ${err.message}`, err.stack);
      });
    } catch (e) {
      this.logger.warn(`Failed to initialize PayoutWorker: ${e.message}`);
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
