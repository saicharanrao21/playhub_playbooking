import { Injectable, Logger, InternalServerErrorException } from '@nestjs/common';
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
    if (!this.razorpay) {
      throw new InternalServerErrorException('Razorpay provider not initialized');
    }
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

  verifyWebhookSignature(rawBody: string, signature: string): boolean {
    const webhookSecret = this.configService.get<string>('RAZORPAY_WEBHOOK_SECRET');

    if (!webhookSecret) {
      this.logger.error('RAZORPAY_WEBHOOK_SECRET is not configured');
      return false;
    }

    const expectedSignature = crypto
      .createHmac('sha256', webhookSecret)
      .update(rawBody)
      .digest('hex');

    return expectedSignature === signature;
  }

  async verifyCheckout(data: any, expectedAmountMinorUnits: number): Promise<boolean> {
    if (!this.razorpay) {
      throw new InternalServerErrorException('Razorpay provider not initialized');
    }
    const secret = this.configService.get<string>('RAZORPAY_KEY_SECRET');
    if (!secret) {
      this.logger.error('RAZORPAY_KEY_SECRET is not configured');
      return false;
    }

    // data contains providerOrderId, providerPaymentId, signature
    const body = data.providerOrderId + '|' + data.providerPaymentId;
    const expectedSignature = crypto
      .createHmac('sha256', secret)
      .update(body)
      .digest('hex');

    if (expectedSignature !== data.signature) {
      return false;
    }

    // Authoritative check
    try {
       const order = await this.razorpay.orders.fetch(data.providerOrderId);
       return order.amount === expectedAmountMinorUnits;
    } catch (error) {
       this.logger.error('Razorpay order fetch failed', error.stack);
       return false;
    }
  }

  async initiateRefund(options: RefundOptions): Promise<RefundResult> {
    if (!this.razorpay) {
      throw new InternalServerErrorException('Razorpay provider not initialized');
    }
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

  async getOrderStatus(orderId: string): Promise<string> {
    if (!this.razorpay) {
      throw new InternalServerErrorException('Razorpay provider not initialized');
    }
    try {
      const order = await this.razorpay.orders.fetch(orderId);
      return order.status; // 'created', 'attempted', 'paid'
    } catch (error) {
      this.logger.error(`Failed to fetch Razorpay order status for ${orderId}`, error.stack);
      throw error;
    }
  }
}
