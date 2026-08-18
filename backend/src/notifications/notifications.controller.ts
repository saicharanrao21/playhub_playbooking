import { Controller, Get, Patch, UseGuards, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { NotificationsService } from './notifications.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OrganizationGuard } from '../common/guards/organization.guard';
import { OrganizationContext } from '../common/decorators/organization-context.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserIdentity } from '../common/interfaces/user-identity.interface';

@ApiTags('notifications')
@Controller('organizations/:organizationId/notifications')
@UseGuards(JwtAuthGuard, OrganizationGuard)
@ApiBearerAuth()
@ApiHeader({ name: 'x-organization-id', required: false })
export class NotificationsController {
  constructor(private readonly notificationsService: NotificationsService) {}

  @Get()
  @ApiOperation({ summary: "Fetch current user's notifications" })
  async findAll(
    @OrganizationContext() organizationId: string,
    @CurrentUser() user: UserIdentity,
  ) {
    return this.notificationsService.findAll(organizationId, user.userId);
  }

  @Patch(':id/read')
  @ApiOperation({ summary: 'Mark a notification as read' })
  async markAsRead(
    @OrganizationContext() organizationId: string,
    @CurrentUser() user: UserIdentity,
    @Param('id') id: string,
  ) {
    return this.notificationsService.markAsRead(organizationId, user.userId, id);
  }

  @Patch('read-all')
  @ApiOperation({ summary: 'Mark all notifications as read' })
  async markAllAsRead(
    @OrganizationContext() organizationId: string,
    @CurrentUser() user: UserIdentity,
  ) {
    return this.notificationsService.markAllAsRead(organizationId, user.userId);
  }
}
