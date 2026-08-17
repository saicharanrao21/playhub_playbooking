import { Controller, Get, UseGuards, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { OrganizationsService } from './organizations.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard'; // I need to verify this path
import { OrganizationGuard } from '../common/guards/organization.guard';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { PermissionsGuard } from '../common/guards/permissions.guard';
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
  async findAll() {
    return this.organizationsService.findAll();
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
  @RequirePermission('read:organization_settings')
  @ApiOperation({ summary: 'Get organization settings (Requires permission)' })
  async getSettings(@Param('organizationId') orgId: string) {
    return { organizationId: orgId, settings: { theme: 'default' } };
  }
}
