import { Controller, Get, Post, Body, UseGuards, Query, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { FinanceService } from './finance.service';
import { SettlementService } from './settlement.service';
import { PayoutService } from './payout.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OrganizationGuard } from '../common/guards/organization.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { Permissions } from '../common/constants/permissions';
import { OrganizationContext } from '../common/decorators/organization-context.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserIdentity } from '../common/interfaces/user-identity.interface';
import { PaginationDto } from '../common/dto/pagination.dto';
import { RequestPayoutDto } from './dto/request-payout.dto';

@ApiTags('finance')
@Controller('organizations/:organizationId/finance')
@UseGuards(JwtAuthGuard, OrganizationGuard, PermissionsGuard)
@ApiBearerAuth()
@ApiHeader({ name: 'x-organization-id', required: true })
export class FinanceController {
  constructor(
    private readonly financeService: FinanceService,
    private readonly settlementService: SettlementService,
    private readonly payoutService: PayoutService,
  ) {}

  @Get('summary')
  @RequirePermission(Permissions.PAYMENT_READ)
  @ApiOperation({ summary: 'Get comprehensive partner financial summary' })
  async getSummary(@OrganizationContext() organizationId: string) {
    return this.financeService.getPartnerFinancialSummary(organizationId);
  }

  @Get('balance')
  @RequirePermission(Permissions.PAYMENT_READ)
  @ApiOperation({ summary: 'Get partner organization available balance' })
  async getBalance(@OrganizationContext() organizationId: string) {
    return this.financeService.getPartnerBalance(organizationId);
  }

  @Get('transactions')
  @RequirePermission(Permissions.PAYMENT_READ)
  @ApiOperation({ summary: 'Get partner financial transactions' })
  async getTransactions(
    @OrganizationContext() organizationId: string,
    @Query() pagination: PaginationDto,
  ) {
    const [items, total] = await Promise.all([
      this.financeService.getTransactions(organizationId, {
        skip: pagination.skip,
        take: pagination.limit,
      }),
      this.financeService.getTransactionCount(organizationId),
    ]);

    return { items, total };
  }

  @Get('settlements')
  @RequirePermission(Permissions.PAYOUT_READ)
  @ApiOperation({ summary: 'Get partner settlements' })
  async getSettlements(@OrganizationContext() organizationId: string) {
    return this.settlementService.getSettlements(organizationId);
  }

  @Get('payouts')
  @RequirePermission(Permissions.PAYOUT_READ)
  @ApiOperation({ summary: 'Get partner payout history' })
  async getPayouts(@OrganizationContext() organizationId: string) {
    return this.payoutService.getPayouts(organizationId);
  }

  @Post('payouts/request')
  @RequirePermission(Permissions.PAYOUT_REQUEST)
  @ApiOperation({ summary: 'Request a payout for available balance' })
  async requestPayout(
    @OrganizationContext() organizationId: string,
    @CurrentUser() user: UserIdentity,
    @Body() dto: RequestPayoutDto,
  ) {
    return this.payoutService.initiatePayout(organizationId, dto, user.userId);
  }
}
