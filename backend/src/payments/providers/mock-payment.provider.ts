import { Injectable } from '@nestjs/common';
import {
  IPaymentProvider,
  CreateOrderOptions,
  PaymentOrder,
  RefundOptions,
  RefundResult,
} from '../interfaces/payment-provider.interface';
import * as crypto from 'crypto';

@Injectable()
export class MockPaymentProvider implements IPaymentProvider {
  async createOrder(options: CreateOrderOptions): Promise<PaymentOrder> {
    return {
      id: `order_mock_${crypto.randomUUID()}`,
      amount: options.amount,
      currency: options.currency,
    };
  }

  verifyWebhookSignature(rawBody: string, signature: string): boolean {
    // In mock, any signature starting with 'valid_' is fine
    return signature.startsWith('valid_');
  }

  async verifyCheckout(data: any, expectedAmountMinorUnits: number): Promise<boolean> {
     // For mock, we just check the signature pattern
     return data.signature.startsWith('valid_');
  }

  async initiateRefund(options: RefundOptions): Promise<RefundResult> {
    return {
      id: `ref_mock_${crypto.randomUUID()}`,
      status: 'processed',
    };
  }

  async getOrderStatus(orderId: string): Promise<string> {
    return 'paid'; // Always paid in mock for now
  }
}
