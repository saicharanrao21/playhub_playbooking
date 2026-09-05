import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { SupportService } from './support.service';
import { DisputesService } from './disputes.service';
import { ResolveDisputeDto } from './dto/resolve-dispute.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PlatformAdminGuard } from '../common/guards/platform-admin.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserIdentity } from '../common/interfaces/user-identity.interface';

@ApiTags('admin-support')
@Controller('admin/support')
@UseGuards(JwtAuthGuard, PlatformAdminGuard)
@ApiBearerAuth()
export class AdminSupportController {
  constructor(
    private readonly supportService: SupportService,
    private readonly disputesService: DisputesService,
  ) {}

  @Get('tickets')
  @ApiOperation({ summary: 'Admin: List support ticket queue' })
  async getTicketQueue(
    @Query('status') status?: string,
    @Query('category') category?: string,
    @Query('priority') priority?: string,
    @Query('skip') skip?: number,
    @Query('take') take?: number,
  ) {
    return this.supportService.getAdminTicketQueue({
      status,
      category,
      priority,
      skip: Number(skip || 0),
      take: Number(take || 20),
    });
  }

  @Patch('tickets/:id/status')
  @ApiOperation({ summary: 'Admin: Update support ticket status / assign agent' })
  async updateTicketStatus(
    @CurrentUser() admin: UserIdentity,
    @Param('id') id: string,
    @Body('status') status: string,
    @Body('notes') notes?: string,
  ) {
    return this.supportService.updateTicketStatus(admin.userId, id, status, notes);
  }

  @Get('disputes')
  @ApiOperation({ summary: 'Admin: List platform dispute queue' })
  async getDisputeQueue(
    @Query('status') status?: string,
    @Query('organizationId') organizationId?: string,
    @Query('skip') skip?: number,
    @Query('take') take?: number,
  ) {
    return this.disputesService.getAdminDisputeQueue({
      status,
      organizationId,
      skip: Number(skip || 0),
      take: Number(take || 20),
    });
  }

  @Post('disputes/:id/resolve')
  @ApiOperation({ summary: 'Admin: Resolve dispute with refund, goodwill credit, or rejection' })
  async resolveDispute(
    @CurrentUser() admin: UserIdentity,
    @Param('id') id: string,
    @Body() dto: ResolveDisputeDto,
  ) {
    return this.disputesService.resolveDispute(admin.userId, id, dto);
  }
}
