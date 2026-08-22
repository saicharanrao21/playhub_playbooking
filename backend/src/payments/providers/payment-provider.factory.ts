import { Injectable, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { IPaymentProvider } from '../interfaces/payment-provider.interface';
import { RazorpayPaymentProvider } from './razorpay-payment.provider';
import { StripePaymentProvider } from './stripe-payment.provider';
import { MockPaymentProvider } from './mock-payment.provider';
import { PaymentProvider } from '@prisma/client';

@Injectable()
export class PaymentProviderFactory {
  constructor(
    private razorpayProvider: RazorpayPaymentProvider,
    private stripeProvider: StripePaymentProvider,
    private mockProvider: MockPaymentProvider,
  ) {}

  getProvider(type: PaymentProvider): IPaymentProvider {
    switch (type) {
      case PaymentProvider.RAZORPAY:
        return this.razorpayProvider;
      case PaymentProvider.STRIPE:
        return this.stripeProvider;
      case PaymentProvider.MOCK:
        return this.mockProvider;
      default:
        throw new BadRequestException(`Unsupported payment provider: ${type}`);
    }
  }
}
