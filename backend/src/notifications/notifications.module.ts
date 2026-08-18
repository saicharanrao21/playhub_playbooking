import { Module } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { NotificationsController } from './notifications.controller';
import { OrganizationsModule } from '../organizations/organizations.module';
import { BookingEventsListener } from './listeners/booking-events.listener';

@Module({
  imports: [OrganizationsModule],
  controllers: [NotificationsController],
  providers: [NotificationsService, BookingEventsListener],
  exports: [NotificationsService],
})
export class NotificationsModule {}
