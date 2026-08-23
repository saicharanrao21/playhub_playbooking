import { Controller, Post, Body, Req, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { PaymentsService } from './payments.service';
import { Public } from '../common/decorators/public.decorator';

@ApiTags('webhooks')
@Controller('payments/webhooks')
export class WebhooksController {
  constructor(private readonly paymentsService: PaymentsService) {}

  @Public()
  @Post(':provider')
  @ApiOperation({ summary: 'Handle global payment provider webhooks (Tenant-agnostic route)' })
  @HttpCode(HttpStatus.OK)
  async handleWebhook(
    @Req() req: any,
    @Body() payload: any,
  ) {
    const provider = req.params.provider;
    const signature = req.headers['x-razorpay-signature'] || req.headers['stripe-signature'];
    const rawBody = req.rawBody?.toString();
    return this.paymentsService.handleWebhook(provider, payload, signature, rawBody);
  }
}
