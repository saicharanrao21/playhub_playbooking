import { Module, NestModule, MiddlewareConsumer } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { OrganizationsModule } from './organizations/organizations.module';
import { BusinessesModule } from './businesses/businesses.module';
import { VenuesModule } from './venues/venues.module';
import { FacilitiesModule } from './facilities/facilities.module';
import { HealthController } from './health/health.controller';
import { RequestIdMiddleware } from './common/middleware/request-id.middleware';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      cache: true,
    }),
    PrismaModule,
    AuthModule,
    UsersModule,
    OrganizationsModule,
    BusinessesModule,
    VenuesModule,
    FacilitiesModule,
  ],
  controllers: [HealthController],
  providers: [],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(RequestIdMiddleware).forRoutes('*');
  }
}
