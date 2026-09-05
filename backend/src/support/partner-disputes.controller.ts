import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { DisputesService } from './disputes.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OrganizationGuard } from '../common/guards/organization.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { Permissions } from '../common/constants/permissions';
import { OrganizationContext } from '../common/decorators/organization-context.decorator';

@ApiTags('partner-disputes')
@Controller('organizations/:organizationId')
@UseGuards(JwtAuthGuard, OrganizationGuard, PermissionsGuard)
@ApiBearerAuth()
@ApiHeader({ name: 'x-organization-id', required: true })
export class PartnerDisputesController {
  constructor(private readonly disputesService: DisputesService) {}

  @Get('disputes')
  @RequirePermission(Permissions.ORGANIZATION_READ)
  @ApiOperation({ summary: 'Partner: List disputes linked to organization venues/bookings' })
  async getPartnerDisputes(
    @OrganizationContext() organizationId: string,
    @Query('status') status?: string,
    @Query('skip') skip?: number,
    @Query('take') take?: number,
  ) {
    return this.disputesService.getAdminDisputeQueue({
      organizationId,
      status,
      skip: Number(skip || 0),
      take: Number(take || 20),
    });
  }

  @Post('disputes/:id/response')
  @RequirePermission(Permissions.ORGANIZATION_UPDATE)
  @ApiOperation({ summary: 'Partner: Provide organization response/evidence to dispute' })
  async partnerResponse(
    @OrganizationContext() organizationId: string,
    @Param('id') disputeId: string,
    @Body('response') responseText: string,
  ) {
    return this.disputesService.partnerResponse(organizationId, disputeId, responseText);
  }
}
