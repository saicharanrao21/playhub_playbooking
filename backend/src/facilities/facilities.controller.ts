import { Controller, Get, Post, Body, UseGuards, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { FacilitiesService } from './facilities.service';
import { CreateFacilityDto } from './dto/create-facility.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OrganizationGuard } from '../common/guards/organization.guard';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { OrganizationContext } from '../common/decorators/organization-context.decorator';
import { Permissions } from '../common/constants/permissions';

@ApiTags('facilities')
@Controller('organizations/:organizationId/facilities')
@UseGuards(JwtAuthGuard, OrganizationGuard, PermissionsGuard)
@ApiBearerAuth()
@ApiHeader({ name: 'x-organization-id', required: false })
export class FacilitiesController {
  constructor(private readonly facilitiesService: FacilitiesService) {}

  @Post()
  @RequirePermission(Permissions.FACILITY_CREATE)
  @ApiOperation({ summary: 'Create a new facility' })
  async create(
    @OrganizationContext() organizationId: string,
    @Query('venueId') venueId: string,
    @Body() dto: CreateFacilityDto,
  ) {
    return this.facilitiesService.create(organizationId, venueId, dto);
  }

  @Get()
  @RequirePermission(Permissions.FACILITY_READ)
  @ApiOperation({ summary: 'List all facilities for a venue' })
  async findAll(
    @OrganizationContext() organizationId: string,
    @Query('venueId') venueId: string,
  ) {
    return this.facilitiesService.findAll(organizationId, venueId);
  }

  @Get(':id')
  @RequirePermission(Permissions.FACILITY_READ)
  @ApiOperation({ summary: 'Get a specific facility' })
  async findOne(
    @OrganizationContext() organizationId: string,
    @Param('id') id: string,
  ) {
    return this.facilitiesService.findOne(organizationId, id);
  }
}
