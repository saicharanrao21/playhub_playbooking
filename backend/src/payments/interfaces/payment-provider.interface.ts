export const PAYMENT_PROVIDER = 'PAYMENT_PROVIDER';

export interface CreateOrderOptions {
  amount: number; // In minor units (e.g. paise, cents)
  currency: string;
  receipt: string;
  notes?: Record<string, string>;
}

export interface PaymentOrder {
  id: string; // Provider's order ID
  amount: number;
  currency: string;
}

export interface IPaymentProvider {
  createOrder(options: CreateOrderOptions): Promise<PaymentOrder>;
  verifySignature(payload: any, signature: string): boolean;
}
