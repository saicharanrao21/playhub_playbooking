import { Controller, Get, Post, Patch, Delete, Body, UseGuards, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { FacilitiesService } from './facilities.service';
import { CreateFacilityDto } from './dto/create-facility.dto';
import { UpdateFacilityDto } from './dto/update-facility.dto';
import { CreateBlockDto } from './dto/create-block.dto';
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

  @Patch(':id')
  @RequirePermission(Permissions.FACILITY_UPDATE)
  @ApiOperation({ summary: 'Update a facility' })
  async update(
    @OrganizationContext() organizationId: string,
    @Param('id') id: string,
    @Body() dto: UpdateFacilityDto,
  ) {
    return this.facilitiesService.update(organizationId, id, dto);
  }

  @Post(':id/blocks')
  @RequirePermission(Permissions.AVAILABILITY_BLOCK_CREATE)
  @ApiOperation({ summary: 'Create an availability block for a facility' })
  async createBlock(
    @OrganizationContext() organizationId: string,
    @Param('id') id: string,
    @Body() dto: CreateBlockDto,
  ) {
    return this.facilitiesService.createBlock(organizationId, id, dto);
  }

  @Delete(':id/blocks/:blockId')
  @RequirePermission(Permissions.AVAILABILITY_BLOCK_DELETE)
  @ApiOperation({ summary: 'Remove an availability block' })
  async deleteBlock(
    @OrganizationContext() organizationId: string,
    @Param('id') id: string,
    @Param('blockId') blockId: string,
  ) {
    return this.facilitiesService.deleteBlock(organizationId, id, blockId);
  }
}
