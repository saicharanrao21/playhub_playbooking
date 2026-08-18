# Payment Provider Setup Guide

PlayHub supports multiple payment providers through a clean abstraction layer. This guide details how to configure Razorpay and Stripe.

## 💳 Provider Abstraction
The `IPaymentProvider` interface decouples the core `PaymentsService` from specific SDKs. The `PaymentProviderFactory` resolves the correct implementation at runtime based on the requested provider or organization configuration.

---

## 🇮🇳 Razorpay Setup (Primary for India)

### 1. Dashboard Configuration
- Create an account at [Razorpay](https://razorpay.com).
- Navigate to **Settings > API Keys** to generate `Key ID` and `Key Secret`.
- Navigate to **Settings > Webhooks**:
  - Add a webhook URL: `https://your-domain.com/api/v1/organizations/{orgId}/payments/webhook/razorpay`
  - Active Events: `payment.captured`, `refund.processed`.
  - Set a `Webhook Secret`.

### 2. Environment Variables
```env
RAZORPAY_KEY_ID="rzp_test_..."
RAZORPAY_KEY_SECRET="..."
RAZORPAY_WEBHOOK_SECRET="..."
```

---

## 🌍 Stripe Setup (International)

### 1. Dashboard Configuration
- Create an account at [Stripe](https://stripe.com).
- Navigate to **Developers > API keys** to get your `Secret key`.
- Navigate to **Developers > Webhooks**:
  - Add an endpoint: `https://your-domain.com/api/v1/organizations/{orgId}/payments/webhook/stripe`
  - Select events: `payment_intent.succeeded`, `charge.refunded`.
  - Reveal the `Signing secret`.

### 2. Environment Variables
```env
STRIPE_SECRET_KEY="sk_test_..."
STRIPE_WEBHOOK_SECRET="whsec_..."
```

---

## 🛡️ Security Requirements

1. **Server Authority**: Final payment confirmation is **never** based on a client-side response. Backend signature verification (HMAC for Razorpay, official SDK for Stripe) is mandatory.
2. **Smallest Unit**: All amounts are handled in the smallest currency unit (e.g., Paise for INR, Cents for USD) as integers to prevent floating-point errors.
3. **Idempotency**: Webhooks are processed using the provider's `order_id` or `payment_intent_id` and atomic database checks to prevent double-confirmation.
4. **Tenant Isolation**: Every payment order and webhook event is validated against the target organization's context.
