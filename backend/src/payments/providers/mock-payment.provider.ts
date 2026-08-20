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

  verifySignature(payload: any, signature: string): boolean {
    // In mock, any signature starting with 'valid_' is fine
    return signature.startsWith('valid_');
  }

  async verifyCheckout(data: any): Promise<boolean> {
     return data.signature.startsWith('valid_');
  }

  async initiateRefund(options: RefundOptions): Promise<RefundResult> {
    return {
      id: `ref_mock_${crypto.randomUUID()}`,
      status: 'processed',
    };
  }
}
