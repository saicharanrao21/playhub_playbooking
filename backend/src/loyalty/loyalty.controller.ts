import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { LoyaltyService } from './loyalty.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PlatformAdminGuard } from '../common/guards/platform-admin.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserIdentity } from '../common/interfaces/user-identity.interface';

@ApiTags('loyalty')
@Controller()
export class LoyaltyController {
  constructor(private readonly loyaltyService: LoyaltyService) {}

  @Get('loyalty/account')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get user loyalty account balance' })
  async getAccount(@CurrentUser() user: UserIdentity) {
    return this.loyaltyService.getAccount(user.userId);
  }

  @Get('loyalty/transactions')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get user loyalty transaction history' })
  async getTransactions(
    @CurrentUser() user: UserIdentity,
    @Query('skip') skip?: number,
    @Query('take') take?: number,
  ) {
    return this.loyaltyService.getTransactions(user.userId, Number(skip || 0), Number(take || 20));
  }

  @Get('loyalty/referral-code')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get or generate user referral code' })
  async getReferralCode(@CurrentUser() user: UserIdentity) {
    return this.loyaltyService.getOrCreateReferralCode(user.userId);
  }

  @Post('loyalty/referrals/apply')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Apply referral code during signup/onboarding' })
  async applyReferralCode(
    @CurrentUser() user: UserIdentity,
    @Body('code') code: string,
  ) {
    return this.loyaltyService.applyReferralCode(user.userId, code);
  }

  @Post('admin/loyalty/adjust')
  @UseGuards(JwtAuthGuard, PlatformAdminGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Admin: Issue manual loyalty point adjustment' })
  async adminAdjustPoints(
    @Body('userId') userId: string,
    @Body('points') points: number,
    @Body('reason') reason: string,
  ) {
    if (points > 0) {
      return this.loyaltyService.earnPoints(userId, points, 'ADMIN_ADJUSTMENT', reason);
    } else {
      return this.loyaltyService.redeemPoints(userId, Math.abs(points), 'ADMIN_ADJUSTMENT', reason);
    }
  }
}
