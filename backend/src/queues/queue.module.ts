import { Module, Global } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { QueueService } from './queue.service';
import { NotificationWorker } from './workers/notification.worker';
import { ReconciliationWorker } from './workers/reconciliation.worker';
import { SettlementWorker } from './workers/settlement.worker';
import { PayoutWorker } from './workers/payout.worker';
import { NotificationsModule } from '../notifications/notifications.module';
import { FinanceModule } from '../finance/finance.module';

@Global()
@Module({
  imports: [ConfigModule, NotificationsModule, FinanceModule],
  providers: [
    QueueService,
    NotificationWorker,
    ReconciliationWorker,
    SettlementWorker,
    PayoutWorker,
  ],
  exports: [QueueService],
})
export class QueueModule {}
