import { Controller, Get, Post, Patch, Delete, Body, UseGuards, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { FacilitiesService } from './facilities.service';
import { CreateFacilityDto } from './dto/create-facility.dto';
import { UpdateFacilityDto } from './dto/update-facility.dto';
import { CreateBlockDto } from './dto/create-block.dto';
import { CreatePricingRuleDto } from './dto/create-pricing-rule.dto';
import { PaginationDto } from '../common/dto/pagination.dto';
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
    @Query() pagination: PaginationDto,
  ) {
    return this.facilitiesService.findAll(organizationId, venueId, {
      skip: pagination.skip,
      take: pagination.limit,
    });
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

  @Get(':id/pricing-rules')
  @RequirePermission(Permissions.PRICING_READ)
  @ApiOperation({ summary: 'Get all pricing rules for a facility' })
  async getPricingRules(
    @OrganizationContext() organizationId: string,
    @Param('id') id: string,
  ) {
    return this.facilitiesService.getPricingRules(organizationId, id);
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

  @Post(':id/pricing-rules')
  @RequirePermission(Permissions.PRICING_CREATE)
  @ApiOperation({ summary: 'Create a pricing rule for a facility' })
  async createPricingRule(
    @OrganizationContext() organizationId: string,
    @Param('id') id: string,
    @Body() dto: CreatePricingRuleDto,
  ) {
    return this.facilitiesService.createPricingRule(organizationId, id, dto);
  }

  @Delete(':id/pricing-rules/:ruleId')
  @RequirePermission(Permissions.PRICING_DELETE)
  @ApiOperation({ summary: 'Remove a pricing rule' })
  async deletePricingRule(
    @OrganizationContext() organizationId: string,
    @Param('id') id: string,
    @Param('ruleId') ruleId: string,
  ) {
    return this.facilitiesService.deletePricingRule(organizationId, id, ruleId);
  }
}
