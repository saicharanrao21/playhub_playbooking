import { Module } from '@nestjs/common';
import { VenuesService } from './venues.service';
import { VenuesController } from './venues.controller';
import { OrganizationsModule } from '../organizations/organizations.module';
import { GeocodingService } from '../common/services/geocoding.service';

@Module({
  imports: [OrganizationsModule],
  controllers: [VenuesController],
  providers: [VenuesService, GeocodingService],
  exports: [VenuesService, GeocodingService],
})
export class VenuesModule {}
