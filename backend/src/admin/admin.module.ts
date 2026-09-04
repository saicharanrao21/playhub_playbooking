import { Module } from '@nestjs/common';
import { AdminService } from './admin.service';
import { AdminController } from './admin.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { AuditService } from '../common/services/audit.service';
import { OrganizationsModule } from '../organizations/organizations.module';
import { VenuesModule } from '../venues/venues.module';

@Module({
  imports: [PrismaModule, OrganizationsModule, VenuesModule],
  controllers: [AdminController],
  providers: [AdminService, AuditService],
  exports: [AdminService],
})
export class AdminModule {}
