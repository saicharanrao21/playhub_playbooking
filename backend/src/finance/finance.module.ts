import { Module } from '@nestjs/common';
import { FinanceService } from './finance.service';
import { FinanceController } from './finance.controller';
import { FinanceEventsListener } from './listeners/finance-events.listener';
import { PrismaModule } from '../prisma/prisma.module';
import { OrganizationsModule } from '../organizations/organizations.module';

@Module({
  imports: [PrismaModule, OrganizationsModule],
  controllers: [FinanceController],
  providers: [FinanceService, FinanceEventsListener],
  exports: [FinanceService],
})
export class FinanceModule {}
