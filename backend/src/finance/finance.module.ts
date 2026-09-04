import { Module } from '@nestjs/common';
import { FinanceService } from './finance.service';
import { SettlementService } from './settlement.service';
import { PayoutService } from './payout.service';
import { ReconciliationService } from './reconciliation.service';
import { FinanceController } from './finance.controller';
import { AdminFinanceController } from './admin-finance.controller';
import { FinanceEventsListener } from './listeners/finance-events.listener';
import { PrismaModule } from '../prisma/prisma.module';
import { OrganizationsModule } from '../organizations/organizations.module';
import { AuditService } from '../common/services/audit.service';

@Module({
  imports: [PrismaModule, OrganizationsModule],
  controllers: [FinanceController, AdminFinanceController],
  providers: [
    FinanceService,
    SettlementService,
    PayoutService,
    ReconciliationService,
    FinanceEventsListener,
    AuditService,
  ],
  exports: [FinanceService, SettlementService, PayoutService, ReconciliationService],
})
export class FinanceModule {}
