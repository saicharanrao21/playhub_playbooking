import { Controller, Get, Post, Patch, Body, UseGuards, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { OrganizationsService } from './organizations.service';
import { UpdateOrganizationDto } from './dto/update-organization.dto';
import { OnboardPartnerDto } from './dto/onboard-partner.dto';
import { PaginationDto } from '../common/dto/pagination.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OrganizationGuard } from '../common/guards/organization.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { Permissions } from '../common/constants/permissions';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserIdentity } from '../common/interfaces/user-identity.interface';
import { OrganizationContext } from '../common/decorators/organization-context.decorator';

@ApiTags('organizations')
@Controller('organizations')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class OrganizationsController {
  constructor(private readonly organizationsService: OrganizationsService) {}

  @Get()
  @ApiOperation({ summary: 'List all organizations (Public/Global view)' })
  async findAll(@Query() pagination: PaginationDto) {
    return this.organizationsService.findAll({
      skip: pagination.skip,
      take: pagination.limit,
    });
  }

  @Get('my')
  @ApiOperation({ summary: 'Get current user memberships and organizations' })
  async getMyOrganizations(@CurrentUser() user: UserIdentity) {
    return this.organizationsService.getUserOrganizations(user.userId);
  }

  @Post('onboard')
  @ApiOperation({ summary: 'Onboard a new partner organization and business' })
  async onboardPartner(
    @CurrentUser() user: UserIdentity,
    @Body() dto: OnboardPartnerDto,
  ) {
    return this.organizationsService.onboardPartner(user.userId, dto);
  }

  @Get('dashboard/stats')
  @UseGuards(OrganizationGuard)
  @ApiHeader({ name: 'x-organization-id', required: true })
  @ApiOperation({ summary: 'Get organization dashboard summary' })
  async getDashboardStats(@OrganizationContext() organizationId: string) {
    return this.organizationsService.getDashboardStats(organizationId);
  }

  @Patch(':organizationId')
  @UseGuards(OrganizationGuard, PermissionsGuard)
  @RequirePermission(Permissions.ORGANIZATION_UPDATE)
  @ApiHeader({ name: 'x-organization-id', required: true })
  @ApiOperation({ summary: 'Update organization details' })
  async update(
    @Param('organizationId') id: string,
    @Body() dto: UpdateOrganizationDto,
  ) {
    return this.organizationsService.update(id, dto);
  }

  @Get(':organizationId/my-profile')
  @UseGuards(OrganizationGuard)
  @ApiHeader({ name: 'x-organization-id', required: false, description: 'Organization ID context' })
  @ApiOperation({ summary: 'Get current user identity within an organization context' })
  async getMyOrgProfile(@CurrentUser() user: UserIdentity) {
    return user;
  }

  @Get(':organizationId/settings')
  @UseGuards(OrganizationGuard, PermissionsGuard)
  @RequirePermission(Permissions.ORGANIZATION_SETTINGS_READ)
  @ApiOperation({ summary: 'Get organization settings (Requires permission)' })
  async getSettings(@Param('organizationId') orgId: string) {
    return { organizationId: orgId, settings: { theme: 'default' } };
  }
}
