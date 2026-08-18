import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { IPaymentProvider } from '../interfaces/payment-provider.interface';
import { RazorpayPaymentProvider } from './razorpay-payment.provider';
import { StripePaymentProvider } from './stripe-payment.provider';
import { PaymentProvider } from '@prisma/client';

@Injectable()
export class PaymentProviderFactory {
  constructor(
    private razorpayProvider: RazorpayPaymentProvider,
    private stripeProvider: StripePaymentProvider,
  ) {}

  getProvider(type: PaymentProvider): IPaymentProvider {
    switch (type) {
      case PaymentProvider.RAZORPAY:
        return this.razorpayProvider;
      case PaymentProvider.STRIPE:
        return this.stripeProvider;
      default:
        throw new Error(`Unsupported payment provider: ${type}`);
    }
  }
}
