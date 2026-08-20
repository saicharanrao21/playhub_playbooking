export const PAYMENT_PROVIDER = 'PAYMENT_PROVIDER';

export interface CreateOrderOptions {
  amount: number; // In minor units (e.g. paise, cents)
  currency: string;
  receipt: string;
  notes?: Record<string, string>;
  metadata?: Record<string, any>;
}

export interface PaymentOrder {
  id: string; // Provider's order ID or client secret
  amount: number;
  currency: string;
  providerMetadata?: any;
}

export interface RefundOptions {
  paymentId: string;
  amount?: number; // Optional, full refund if not provided
  notes?: Record<string, string>;
}

export interface RefundResult {
  id: string;
  status: string;
}

export interface IPaymentProvider {
  createOrder(options: CreateOrderOptions): Promise<PaymentOrder>;
  verifySignature(payload: any, signature: string): boolean;
  verifyCheckout?(data: any): Promise<boolean>; // Optional authoritative check
  initiateRefund(options: RefundOptions): Promise<RefundResult>;
}
