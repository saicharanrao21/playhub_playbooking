import { Controller, Get, Post, Body, UseGuards, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { VenuesService } from './venues.service';
import { CreateVenueDto } from './dto/create-venue.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OrganizationGuard } from '../common/guards/organization.guard';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { OrganizationContext } from '../common/decorators/organization-context.decorator';
import { Permissions } from '../common/constants/permissions';

@ApiTags('venues')
@Controller('organizations/:organizationId/venues')
@UseGuards(JwtAuthGuard, OrganizationGuard, PermissionsGuard)
@ApiBearerAuth()
@ApiHeader({ name: 'x-organization-id', required: false })
export class VenuesController {
  constructor(private readonly venuesService: VenuesService) {}

  @Post()
  @RequirePermission(Permissions.VENUE_CREATE)
  @ApiOperation({ summary: 'Create a new venue' })
  async create(
    @OrganizationContext() organizationId: string,
    @Query('businessId') businessId: string,
    @Body() dto: CreateVenueDto,
  ) {
    return this.venuesService.create(organizationId, businessId, dto);
  }

  @Get()
  @RequirePermission(Permissions.VENUE_READ)
  @ApiOperation({ summary: 'List all venues for a business' })
  async findAll(
    @OrganizationContext() organizationId: string,
    @Query('businessId') businessId: string,
  ) {
    return this.venuesService.findAll(organizationId, businessId);
  }

  @Get(':id')
  @RequirePermission(Permissions.VENUE_READ)
  @ApiOperation({ summary: 'Get a specific venue' })
  async findOne(
    @OrganizationContext() organizationId: string,
    @Param('id') id: string,
  ) {
    return this.venuesService.findOne(organizationId, id);
  }
}
