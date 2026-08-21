import { Controller, Get, UseGuards, Param, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { OrganizationsService } from './organizations.service';
import { PaginationDto } from '../common/dto/pagination.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OrganizationGuard } from '../common/guards/organization.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { Permissions } from '../common/constants/permissions';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserIdentity } from '../common/interfaces/user-identity.interface';

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
