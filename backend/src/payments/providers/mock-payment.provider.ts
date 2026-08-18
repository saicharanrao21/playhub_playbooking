import { Injectable } from '@nestjs/common';
import { IPaymentProvider, CreateOrderOptions, PaymentOrder } from '../interfaces/payment-provider.interface';
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
}
