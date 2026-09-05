import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  Query,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { MembershipsService } from './memberships.service';
import { CreateMembershipPlanDto } from './dto/create-membership-plan.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OrganizationGuard } from '../common/guards/organization.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { Permissions } from '../common/constants/permissions';
import { OrganizationContext } from '../common/decorators/organization-context.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserIdentity } from '../common/interfaces/user-identity.interface';
import { Public } from '../common/decorators/public.decorator';

@ApiTags('memberships')
@Controller()
export class MembershipsController {
  constructor(private readonly membershipsService: MembershipsService) {}

  @Public()
  @Get('memberships/plans')
  @ApiOperation({ summary: 'Get active membership plans' })
  async getPlans(@Query('organizationId') organizationId?: string) {
    return this.membershipsService.getPlans(organizationId);
  }

  @Get('memberships/my-membership')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get user active customer membership' })
  async getMyMembership(@CurrentUser() user: UserIdentity) {
    return this.membershipsService.getActiveCustomerMembership(user.userId);
  }

  @Post('memberships/purchase')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Purchase & activate customer membership' })
  async purchaseMembership(
    @CurrentUser() user: UserIdentity,
    @Body('planId') planId: string,
    @Body('paymentId') paymentId?: string,
  ) {
    return this.membershipsService.purchaseMembership(user.userId, planId, paymentId);
  }

  @Post('organizations/:organizationId/membership-plans')
  @UseGuards(JwtAuthGuard, OrganizationGuard, PermissionsGuard)
  @RequirePermission(Permissions.ORGANIZATION_UPDATE)
  @ApiBearerAuth()
  @ApiHeader({ name: 'x-organization-id', required: true })
  @ApiOperation({ summary: 'Create new organization membership plan' })
  async createPlan(
    @OrganizationContext() organizationId: string,
    @Body() dto: CreateMembershipPlanDto,
  ) {
    return this.membershipsService.createPlan({ ...dto, organizationId });
  }
}
