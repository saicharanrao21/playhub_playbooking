import { Module } from '@nestjs/common';
import { DiscoveryController } from './discovery.controller';
import { VenuesModule } from '../venues/venues.module';

@Module({
  imports: [VenuesModule],
  controllers: [DiscoveryController],
})
export class DiscoveryModule {}
