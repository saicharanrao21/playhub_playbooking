import {
  Controller,
  Get,
  Post,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { WebhooksService } from './webhooks.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PlatformAdminGuard } from '../common/guards/platform-admin.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserIdentity } from '../common/interfaces/user-identity.interface';
import { PaginationDto } from '../common/dto/pagination.dto';

@ApiTags('admin-webhooks')
@Controller('admin/webhooks')
@UseGuards(JwtAuthGuard, PlatformAdminGuard)
@ApiBearerAuth()
export class AdminWebhooksController {
  constructor(private readonly webhooksService: WebhooksService) {}

  @Get()
  @ApiOperation({ summary: 'List platform-wide payment webhook logs' })
  getWebhookLogs(
    @Query() pagination: PaginationDto,
    @Query('provider') provider?: string,
    @Query('status') status?: string,
    @Query('paymentId') paymentId?: string,
    @Query('organizationId') organizationId?: string,
  ) {
    return this.webhooksService.getWebhookLogs({
      provider,
      status,
      paymentId,
      organizationId,
      skip: pagination.skip,
      take: pagination.limit,
    });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get detailed webhook event log & payload' })
  getWebhookLogById(@Param('id') id: string) {
    return this.webhooksService.getWebhookLogById(id);
  }

  @Post(':id/retry')
  @ApiOperation({ summary: 'Retry processing for a failed or stuck webhook event' })
  retryWebhookEvent(
    @CurrentUser() admin: UserIdentity,
    @Param('id') id: string,
  ) {
    return this.webhooksService.retryWebhookEvent(admin.userId, id);
  }
}
