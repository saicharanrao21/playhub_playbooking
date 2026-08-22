import { Module, NestModule, MiddlewareConsumer } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { EventEmitterModule } from '@nestjs/event-emitter';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { OrganizationsModule } from './organizations/organizations.module';
import { BusinessesModule } from './businesses/businesses.module';
import { VenuesModule } from './venues/venues.module';
import { FacilitiesModule } from './facilities/facilities.module';
import { AvailabilityModule } from './availability/availability.module';
import { BookingsModule } from './bookings/bookings.module';
import { PaymentsModule } from './payments/payments.module';
import { NotificationsModule } from './notifications/notifications.module';
import { HealthController } from './health/health.controller';
import { RequestIdMiddleware } from './common/middleware/request-id.middleware';

import { validate } from './common/config/env.validation';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      cache: true,
      validate,
    }),
    ThrottlerModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => [
        {
          ttl: config.get('THROTTLE_TTL', 60000),
          limit: config.get('THROTTLE_LIMIT', 100),
        },
      ],
    }),
    EventEmitterModule.forRoot(),
    PrismaModule,
    AuthModule,
    UsersModule,
    OrganizationsModule,
    BusinessesModule,
    VenuesModule,
    FacilitiesModule,
    AvailabilityModule,
    BookingsModule,
    PaymentsModule,
    NotificationsModule,
  ],
  controllers: [HealthController],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(RequestIdMiddleware).forRoutes('*');
  }
}
