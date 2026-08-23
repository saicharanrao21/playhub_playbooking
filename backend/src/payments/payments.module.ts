import { Module } from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { PaymentsController } from './payments.controller';
import { OrganizationsModule } from '../organizations/organizations.module';
import { RazorpayPaymentProvider } from './providers/razorpay-payment.provider';
import { StripePaymentProvider } from './providers/stripe-payment.provider';
import { PaymentProviderFactory } from './providers/payment-provider.factory';
import { MockPaymentProvider } from './providers/mock-payment.provider';
import { PAYMENT_PROVIDER } from './interfaces/payment-provider.interface';

import { WebhooksController } from './webhooks.controller';

@Module({
  imports: [OrganizationsModule],
  controllers: [PaymentsController, WebhooksController],
  providers: [
    PaymentsService,
    RazorpayPaymentProvider,
    StripePaymentProvider,
    PaymentProviderFactory,
    {
      provide: PAYMENT_PROVIDER,
      useClass: MockPaymentProvider, // Default for simple injection
    },
  ],
  exports: [PaymentsService],
})
export class PaymentsModule {}
