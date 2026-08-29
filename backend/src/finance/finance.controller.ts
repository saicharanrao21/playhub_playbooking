import { Controller, Get, UseGuards, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { FinanceService } from './finance.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OrganizationGuard } from '../common/guards/organization.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { Permissions } from '../common/constants/permissions';
import { OrganizationContext } from '../common/decorators/organization-context.decorator';
import { PaginationDto } from '../common/dto/pagination.dto';

@ApiTags('finance')
@Controller('organizations/:organizationId/finance')
@UseGuards(JwtAuthGuard, OrganizationGuard, PermissionsGuard)
@ApiBearerAuth()
@ApiHeader({ name: 'x-organization-id', required: true })
export class FinanceController {
  constructor(private readonly financeService: FinanceService) {}

  @Get('balance')
  @RequirePermission(Permissions.PAYMENT_READ)
  @ApiOperation({ summary: 'Get partner organization balance' })
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
}
