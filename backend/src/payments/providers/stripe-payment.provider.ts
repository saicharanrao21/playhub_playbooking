import { Injectable, Logger, InternalServerErrorException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';
import {
  IPaymentProvider,
  CreateOrderOptions,
  PaymentOrder,
  RefundOptions,
  RefundResult,
} from '../interfaces/payment-provider.interface';

@Injectable()
export class StripePaymentProvider implements IPaymentProvider {
  private readonly logger = new Logger(StripePaymentProvider.name);
  private stripe: Stripe;

  constructor(private configService: ConfigService) {
    const secretKey = this.configService.get<string>('STRIPE_SECRET_KEY');
    if (secretKey) {
      this.stripe = new Stripe(secretKey, {
        apiVersion: '2023-10-16' as any,
      });
    }
  }

  async createOrder(options: CreateOrderOptions): Promise<PaymentOrder> {
    if (!this.stripe) {
      throw new InternalServerErrorException('Stripe provider not initialized');
    }
    try {
      const intent = await this.stripe.paymentIntents.create({
        amount: options.amount,
        currency: options.currency.toLowerCase(),
        description: `Booking ${options.receipt}`,
        metadata: {
          ...options.notes,
          ...options.metadata,
          receipt: options.receipt,
        },
      });

      return {
        id: intent.client_secret as string,
        amount: intent.amount,
        currency: intent.currency.toUpperCase(),
        providerMetadata: {
          paymentIntentId: intent.id,
        },
      };
    } catch (error) {
      this.logger.error('Failed to create Stripe PaymentIntent', error.stack);
      throw error;
    }
  }

  verifySignature(payload: any, signature: string): boolean {
    const secret = this.configService.get<string>('STRIPE_WEBHOOK_SECRET');
    if (!secret) {
      this.logger.error('STRIPE_WEBHOOK_SECRET is not configured');
      return false;
    }

    try {
      this.stripe.webhooks.constructEvent(payload, signature, secret);
      return true;
    } catch (err) {
      this.logger.warn(`Stripe webhook signature verification failed: ${err.message}`);
      return false;
    }
  }

  async verifyCheckout(data: any, expectedAmountMinorUnits: number): Promise<boolean> {
    if (!this.stripe) {
      throw new InternalServerErrorException('Stripe provider not initialized');
    }
    try {
      const intent = await this.stripe.paymentIntents.retrieve(data.providerPaymentId);
      // Authoritative check of status and amount
      return intent.status === 'succeeded' && intent.amount === expectedAmountMinorUnits;
    } catch (error) {
      this.logger.error('Stripe PaymentIntent retrieval failed', error.stack);
      return false;
    }
  }

  async initiateRefund(options: RefundOptions): Promise<RefundResult> {
    if (!this.stripe) {
      throw new InternalServerErrorException('Stripe provider not initialized');
    }
    try {
      const refund = await this.stripe.refunds.create({
        payment_intent: options.paymentId,
        amount: options.amount,
        metadata: options.notes,
      });

      return {
        id: refund.id,
        status: refund.status as string,
      };
    } catch (error) {
      this.logger.error('Failed to initiate Stripe refund', error.stack);
      throw error;
    }
  }
}
