import { Controller, Post, Body, UseGuards, Req, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { PaymentsService } from './payments.service';
import { CreatePaymentOrderDto } from './dto/create-payment-order.dto';
import { VerifyPaymentDto } from './dto/verify-payment.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OrganizationGuard } from '../common/guards/organization.guard';
import { OrganizationContext } from '../common/decorators/organization-context.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserIdentity } from '../common/interfaces/user-identity.interface';

@ApiTags('payments')
@Controller('organizations/:organizationId/payments')
@UseGuards(JwtAuthGuard, OrganizationGuard)
@ApiBearerAuth()
@ApiHeader({ name: 'x-organization-id', required: false })
@ApiHeader({ name: 'x-idempotency-key', required: false })
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Post('order')
  @ApiOperation({ summary: 'Initialize a payment order for a booking' })
  async createOrder(
    @OrganizationContext() organizationId: string,
    @CurrentUser() user: UserIdentity,
    @Body() dto: CreatePaymentOrderDto,
    @Req() req: any,
  ) {
    const idempotencyKey = req.headers['x-idempotency-key'];
    return this.paymentsService.createOrder(organizationId, user.userId, dto, idempotencyKey);
  }

  @Post('verify')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Verify a payment from provider' })
  async verifyPayment(
    @OrganizationContext() organizationId: string,
    @CurrentUser() user: UserIdentity,
    @Body() dto: VerifyPaymentDto,
  ) {
    return this.paymentsService.verifyPayment(organizationId, user.userId, dto);
  }

  @Post('webhook/:provider')
  @ApiOperation({ summary: 'Handle payment provider webhooks (Public endpoint but internally verified)' })
  // Webhooks are usually not under JwtAuthGuard
  async handleWebhook(
    @Req() req: any,
    @Body() payload: any,
  ) {
    const provider = req.params.provider;
    const signature = req.headers['x-razorpay-signature'] || req.headers['stripe-signature'];
    return this.paymentsService.handleWebhook(provider, payload, signature);
  }
}
