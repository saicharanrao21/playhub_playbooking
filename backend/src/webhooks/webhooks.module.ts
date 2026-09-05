import { Module } from '@nestjs/common';
import { WebhooksService } from './webhooks.service';
import { WebhookWorker } from './webhooks.worker';
import { WebhooksController } from './webhooks.controller';
import { AdminWebhooksController } from './admin-webhooks.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { PaymentsModule } from '../payments/payments.module';
import { FinanceModule } from '../finance/finance.module';
import { AuditService } from '../common/services/audit.service';

@Module({
  imports: [PrismaModule, PaymentsModule, FinanceModule],
  controllers: [WebhooksController, AdminWebhooksController],
  providers: [WebhooksService, WebhookWorker, AuditService],
  exports: [WebhooksService],
})
export class WebhooksModule {}
