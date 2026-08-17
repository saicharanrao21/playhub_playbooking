import { Module } from '@nestjs/common';
import { BookingsService } from './bookings.service';
import { BookingsController } from './bookings.controller';
import { OrganizationsModule } from '../organizations/organizations.module';
import { AvailabilityModule } from '../availability/availability.module';

@Module({
  imports: [OrganizationsModule, AvailabilityModule],
  controllers: [BookingsController],
  providers: [BookingsService],
})
export class BookingsModule {}
