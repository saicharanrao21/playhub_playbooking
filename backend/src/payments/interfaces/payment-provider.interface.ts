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
  /**
   * Verifies webhook signature.
   * @param rawBody The raw request body as string
   * @param signature The signature from headers
   */
  verifyWebhookSignature(rawBody: string, signature: string): boolean;
  verifyCheckout?(data: any, expectedAmountMinorUnits: number): Promise<boolean>;
  initiateRefund(options: RefundOptions): Promise<RefundResult>;
  getOrderStatus?(orderId: string): Promise<string>;
}

export const PAYMENT_PROVIDER = 'PAYMENT_PROVIDER';
