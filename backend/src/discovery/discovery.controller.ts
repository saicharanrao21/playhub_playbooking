import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { VenuesService } from '../venues/venues.service';
import { DiscoveryFiltersDto } from './dto/discovery-filters.dto';
import { Public } from '../common/decorators/public.decorator';

@ApiTags('discovery')
@Controller('discovery')
export class DiscoveryController {
  constructor(private readonly venuesService: VenuesService) {}

  @Public()
  @Get('venues')
  @ApiOperation({ summary: 'Global venue discovery search' })
  async discover(@Query() filters: DiscoveryFiltersDto) {
    return this.venuesService.discover(filters);
  }
}
