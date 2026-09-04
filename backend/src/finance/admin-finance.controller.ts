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
import { FinanceService } from './finance.service';
import { SettlementService } from './settlement.service';
import { PayoutService } from './payout.service';
import { ReconciliationService } from './reconciliation.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PlatformAdminGuard } from '../common/guards/platform-admin.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserIdentity } from '../common/interfaces/user-identity.interface';
import { CreateCommissionConfigDto } from './dto/create-commission-config.dto';
import { CreateAdjustmentDto } from './dto/create-adjustment.dto';
import { CreateSettlementDto } from './dto/create-settlement.dto';
import { ReconciliationQueryDto } from './dto/reconciliation-query.dto';
import { PaginationDto } from '../common/dto/pagination.dto';

@ApiTags('admin-finance')
@Controller('admin/finance')
@UseGuards(JwtAuthGuard, PlatformAdminGuard)
@ApiBearerAuth()
export class AdminFinanceController {
  constructor(
    private readonly financeService: FinanceService,
    private readonly settlementService: SettlementService,
    private readonly payoutService: PayoutService,
    private readonly reconciliationService: ReconciliationService,
  ) {}

  @Get('reconciliation')
  @ApiOperation({ summary: 'Run financial reconciliation across payments, transactions & ledger' })
  async getReconciliation(@Query() query: ReconciliationQueryDto) {
    return this.reconciliationService.runReconciliation(query);
  }

  @Get('overview')
  @ApiOperation({ summary: 'Platform-wide financial overview & balances' })
  async getPlatformOverview() {
    return this.reconciliationService.runReconciliation({});
  }

  @Get('commissions')
  @ApiOperation({ summary: 'List all commission configurations' })
  async getCommissionConfigs() {
    return this.financeService.getCommissionConfigs();
  }

  @Post('commissions')
  @ApiOperation({ summary: 'Create new commission configuration rule' })
  async createCommissionConfig(@Body() dto: CreateCommissionConfigDto) {
    return this.financeService.createCommissionConfig(dto);
  }

  @Patch('commissions/:id')
  @ApiOperation({ summary: 'Update/activate/deactivate commission configuration' })
  async updateCommissionConfig(
    @Param('id') id: string,
    @Body() dto: Partial<CreateCommissionConfigDto>,
  ) {
    return this.financeService.updateCommissionConfig(id, dto);
  }

  @Post('adjustments')
  @ApiOperation({ summary: 'Issue governed partner financial adjustment (Credit/Debit)' })
  async createAdjustment(
    @CurrentUser() admin: UserIdentity,
    @Body() dto: CreateAdjustmentDto,
  ) {
    return this.financeService.recordAdjustment(admin.userId, dto);
  }

  @Get('settlements')
  @ApiOperation({ summary: 'Get all settlements across all organizations' })
  async getAllSettlements() {
    return this.settlementService.getAllSettlements();
  }

  @Post('settlements/generate')
  @ApiOperation({ summary: 'Generate finalized settlement for an organization' })
  async createSettlement(@Body() dto: CreateSettlementDto) {
    return this.settlementService.createSettlement(dto);
  }

  @Get('payouts')
  @ApiOperation({ summary: 'Get all payouts across all organizations' })
  async getAllPayouts() {
    return this.payoutService.getAllPayouts();
  }

  @Post('payouts/:id/complete')
  @ApiOperation({ summary: 'Mark payout completed with provider reference' })
  async completePayout(
    @CurrentUser() admin: UserIdentity,
    @Param('id') id: string,
    @Body('providerReference') providerReference: string,
  ) {
    return this.payoutService.completePayout(id, providerReference || 'MOCK_REF_123', admin.userId);
  }

  @Post('payouts/:id/fail')
  @ApiOperation({ summary: 'Mark payout failed and restore partner payable balance' })
  async failPayout(
    @CurrentUser() admin: UserIdentity,
    @Param('id') id: string,
    @Body('reason') reason: string,
  ) {
    return this.payoutService.failPayout(id, reason || 'Bank transfer failed', admin.userId);
  }
}
