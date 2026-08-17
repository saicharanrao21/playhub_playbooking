import { Module } from '@nestjs/common';
import { FacilitiesService } from './facilities.service';
import { FacilitiesController } from './facilities.controller';
import { OrganizationsModule } from '../organizations/organizations.module';

@Module({
  imports: [OrganizationsModule],
  controllers: [FacilitiesController],
  providers: [FacilitiesService],
})
export class FacilitiesModule {}
