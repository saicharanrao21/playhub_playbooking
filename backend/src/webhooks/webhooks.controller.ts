import { Controller, Post, Body, Req, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { WebhooksService } from './webhooks.service';
import { Public } from '../common/decorators/public.decorator';

@ApiTags('webhooks')
@Controller()
export class WebhooksController {
  constructor(private readonly webhooksService: WebhooksService) {}

  @Public()
  @Post('webhooks/:provider')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Receive payment gateway webhooks (Razorpay / Stripe)' })
  async handleWebhook(
    @Req() req: any,
    @Body() payload: any,
  ) {
    const provider = req.params.provider;
    const signature =
      req.headers['x-razorpay-signature'] ||
      req.headers['stripe-signature'] ||
      '';
    const rawBody = req.rawBody?.toString();

    return this.webhooksService.receiveWebhook(provider, payload, signature, rawBody);
  }

  @Public()
  @Post('payments/webhooks/:provider')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Backward-compatible payment gateway webhook receiver' })
  async handleLegacyWebhook(
    @Req() req: any,
    @Body() payload: any,
  ) {
    return this.handleWebhook(req, payload);
  }
}
