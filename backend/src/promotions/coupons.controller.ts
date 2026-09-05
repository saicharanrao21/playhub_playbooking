import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { CouponsService } from './coupons.service';
import { ValidateCouponDto } from './dto/validate-coupon.dto';
import { CreateCouponDto } from './dto/create-coupon.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OrganizationGuard } from '../common/guards/organization.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { Permissions } from '../common/constants/permissions';
import { OrganizationContext } from '../common/decorators/organization-context.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserIdentity } from '../common/interfaces/user-identity.interface';

@ApiTags('promotions')
@Controller()
export class CouponsController {
  constructor(private readonly couponsService: CouponsService) {}

  @Post('promotions/coupons/validate')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Validate coupon code and compute discount' })
  async validateCoupon(
    @CurrentUser() user: UserIdentity,
    @Body() dto: ValidateCouponDto,
  ) {
    return this.couponsService.validateCoupon(user.userId, dto);
  }

  @Get('organizations/:organizationId/coupons')
  @UseGuards(JwtAuthGuard, OrganizationGuard, PermissionsGuard)
  @RequirePermission(Permissions.ORGANIZATION_READ)
  @ApiBearerAuth()
  @ApiHeader({ name: 'x-organization-id', required: true })
  @ApiOperation({ summary: 'List organization coupons' })
  async getCoupons(@OrganizationContext() organizationId: string) {
    return this.couponsService.getCoupons(organizationId);
  }

  @Post('organizations/:organizationId/coupons')
  @UseGuards(JwtAuthGuard, OrganizationGuard, PermissionsGuard)
  @RequirePermission(Permissions.ORGANIZATION_UPDATE)
  @ApiBearerAuth()
  @ApiHeader({ name: 'x-organization-id', required: true })
  @ApiOperation({ summary: 'Create new organization coupon' })
  async createCoupon(
    @OrganizationContext() organizationId: string,
    @Body() dto: CreateCouponDto,
  ) {
    return this.couponsService.createCoupon({ ...dto, organizationId });
  }
}
