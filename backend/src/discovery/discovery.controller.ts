import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { VenuesService } from '../venues/venues.service';
import { DiscoveryFiltersDto } from './dto/discovery-filters.dto';
import { NearbyVenuesQueryDto } from './dto/nearby-venues-query.dto';
import { Public } from '../common/decorators/public.decorator';
import { GeocodingService } from '../common/services/geocoding.service';

@ApiTags('discovery')
@Controller('discovery')
export class DiscoveryController {
  constructor(
    private readonly venuesService: VenuesService,
    private readonly geocodingService: GeocodingService,
  ) {}

  @Public()
  @Get('venues')
  @ApiOperation({ summary: 'Global venue discovery search' })
  async discover(@Query() filters: DiscoveryFiltersDto) {
    return this.venuesService.discover(filters);
  }

  @Public()
  @Get('venues/nearby')
  @ApiOperation({ summary: 'Radius-based nearby venue discovery with exact distances' })
  async findNearby(@Query() query: NearbyVenuesQueryDto) {
    return this.venuesService.findNearby(query);
  }

  @Public()
  @Get('geocode/reverse')
  @ApiOperation({ summary: 'Reverse geocode coordinates to location name' })
  async reverseGeocode(
    @Query('latitude') latitude: number,
    @Query('longitude') longitude: number,
  ) {
    return this.geocodingService.reverseGeocode(
      Number(latitude || 17.4401),
      Number(longitude || 78.3489),
    );
  }
}
