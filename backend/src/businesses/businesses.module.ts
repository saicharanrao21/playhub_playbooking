import { Module } from '@nestjs/common';
import { BusinessesService } from './businesses.service';
import { BusinessesController } from './businesses.controller';
import { OrganizationsModule } from '../organizations/organizations.module';

@Module({
  imports: [OrganizationsModule],
  controllers: [BusinessesController],
  providers: [BusinessesService],
})
export class BusinessesModule {}
