import { Controller, Get, Post, Body, UseGuards, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { BusinessesService } from './businesses.service';
import { CreateBusinessDto } from './dto/create-business.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OrganizationGuard } from '../common/guards/organization.guard';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { OrganizationContext } from '../common/decorators/organization-context.decorator';
import { Permissions } from '../common/constants/permissions';

@ApiTags('businesses')
@Controller('organizations/:organizationId/businesses')
@UseGuards(JwtAuthGuard, OrganizationGuard, PermissionsGuard)
@ApiBearerAuth()
@ApiHeader({ name: 'x-organization-id', required: false })
export class BusinessesController {
  constructor(private readonly businessesService: BusinessesService) {}

  @Post()
  @RequirePermission(Permissions.BUSINESS_CREATE)
  @ApiOperation({ summary: 'Create a new business' })
  async create(
    @OrganizationContext() organizationId: string,
    @Body() dto: CreateBusinessDto,
  ) {
    return this.businessesService.create(organizationId, dto);
  }

  @Get()
  @RequirePermission(Permissions.BUSINESS_READ)
  @ApiOperation({ summary: 'List all businesses in the organization' })
  async findAll(@OrganizationContext() organizationId: string) {
    return this.businessesService.findAll(organizationId);
  }

  @Get(':id')
  @RequirePermission(Permissions.BUSINESS_READ)
  @ApiOperation({ summary: 'Get a specific business' })
  async findOne(
    @OrganizationContext() organizationId: string,
    @Param('id') id: string,
  ) {
    return this.businessesService.findOne(organizationId, id);
  }
}
