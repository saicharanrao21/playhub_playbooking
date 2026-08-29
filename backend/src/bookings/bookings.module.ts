import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { BookingsService } from './bookings.service';
import { BookingsController } from './bookings.controller';
import { QrService } from './qr.service';
import { OrganizationsModule } from '../organizations/organizations.module';
import { AvailabilityModule } from '../availability/availability.module';

@Module({
  imports: [
    OrganizationsModule,
    AvailabilityModule,
    JwtModule.register({}),
  ],
  controllers: [BookingsController],
  providers: [BookingsService, QrService],
  exports: [BookingsService, QrService],
})
export class BookingsModule {}
