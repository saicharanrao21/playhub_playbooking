# Payment System Architecture

## Overview
PlayHub implements a server-authoritative payment foundation designed to ensure consistency between booking state and financial transactions.

## Payment Lifecycle
- **INITIATED:** Payment record created, provider order ID generated.
- **PENDING:** Client has launched the checkout.
- **AUTHORIZED:** Funds locked by provider (e.g. Razorpay 'authorized' state).
- **CAPTURED:** Payment successful and verified by server.
- **FAILED:** Payment attempt failed.
- **CANCELLED:** User or system cancelled the attempt.
- **REFUNDED:** Funds returned to customer.

## Booking/Payment Consistency
1. **Order Creation:** Server calculates amount from booking data. Flutter cannot override.
2. **Double-Payment Protection:** Server checks for existing `CAPTURED` or `AUTHORIZED` payments before creating a new order.
3. **Authoritative Verification:** Final booking confirmation (`status: CONFIRMED`) only happens after server-side signature verification or webhook processing.
4. **Idempotency:** Webhooks and verification requests are processed using provider references to prevent double-counting.

## Provider Abstraction
The `IPaymentProvider` interface allows swapping between Razorpay, Stripe, or Mock implementations without altering business logic in `PaymentsService`.

## Security
- **No Client Trust:** The amount and status are never trusted from the client.
- **Data Redaction:** CVV, card numbers, and secret keys are never logged or stored.
- **Tenant Isolation:** All payment records are scoped to `organizationId`.
