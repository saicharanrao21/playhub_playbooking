import { Module } from '@nestjs/common';
import { SupportService } from './support.service';
import { DisputesService } from './disputes.service';
import { SupportController } from './support.controller';
import { PartnerDisputesController } from './partner-disputes.controller';
import { AdminSupportController } from './admin-support.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { PaymentsModule } from '../payments/payments.module';
import { LoyaltyModule } from '../loyalty/loyalty.module';
import { OrganizationsModule } from '../organizations/organizations.module';
import { AuditService } from '../common/services/audit.service';

@Module({
  imports: [PrismaModule, PaymentsModule, LoyaltyModule, OrganizationsModule],
  controllers: [
    SupportController,
    PartnerDisputesController,
    AdminSupportController,
  ],
  providers: [SupportService, DisputesService, AuditService],
  exports: [SupportService, DisputesService],
})
export class SupportModule {}
