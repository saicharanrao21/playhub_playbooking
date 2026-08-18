import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
const Razorpay = require('razorpay');
import * as crypto from 'crypto';
import {
  IPaymentProvider,
  CreateOrderOptions,
  PaymentOrder,
  RefundOptions,
  RefundResult,
} from '../interfaces/payment-provider.interface';

@Injectable()
export class RazorpayPaymentProvider implements IPaymentProvider {
  private readonly logger = new Logger(RazorpayPaymentProvider.name);
  private razorpay: any;

  constructor(private configService: ConfigService) {
    const keyId = this.configService.get<string>('RAZORPAY_KEY_ID');
    const keySecret = this.configService.get<string>('RAZORPAY_KEY_SECRET');

    if (keyId && keySecret) {
      this.razorpay = new Razorpay({
        key_id: keyId,
        key_secret: keySecret,
      });
    }
  }

  async createOrder(options: CreateOrderOptions): Promise<PaymentOrder> {
    try {
      const order = await this.razorpay.orders.create({
        amount: options.amount,
        currency: options.currency,
        receipt: options.receipt,
        notes: options.notes,
      });

      return {
        id: order.id,
        amount: order.amount as number,
        currency: order.currency as string,
      };
    } catch (error) {
      this.logger.error('Failed to create Razorpay order', error.stack);
      throw error;
    }
  }

  verifySignature(payload: any, signature: string): boolean {
    const secret = this.configService.get<string>('RAZORPAY_WEBHOOK_SECRET');
    if (!secret) {
      this.logger.error('RAZORPAY_WEBHOOK_SECRET is not configured');
      return false;
    }

    const expectedSignature = crypto
      .createHmac('sha256', secret)
      .update(JSON.stringify(payload))
      .digest('hex');

    return expectedSignature === signature;
  }

  async initiateRefund(options: RefundOptions): Promise<RefundResult> {
    try {
      const refund = await this.razorpay.payments.refund(options.paymentId, {
        amount: options.amount,
        notes: options.notes,
      });

      return {
        id: refund.id,
        status: refund.status,
      };
    } catch (error) {
      this.logger.error('Failed to initiate Razorpay refund', error.stack);
      throw error;
    }
  }
}
