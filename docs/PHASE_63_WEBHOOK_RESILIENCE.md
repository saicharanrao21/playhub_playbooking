# PlayHub Phase 63: Webhook Resilience, Idempotent Gateway Delivery & Webhook Audit Logs

## 1. Executive Summary
Phase 63 implements a production-grade, highly resilient **Payment Webhook Infrastructure** for Razorpay and Stripe. The architecture guarantees fast gateway acknowledgements (<200ms ACK) while ensuring atomic database persistence, strict deduplication (`provider` + `providerEventId` unique constraint), out-of-order state machine handling, asynchronous BullMQ processing, and immutable double-entry ledger integration without duplicate side-effects.

## 2. Webhook Architecture & Event Lifecycle
```
Gateway (Razorpay / Stripe)
  │ (HTTP POST with rawBody & signature header)
  ▼
WebhooksController (`POST /api/v1/webhooks/:provider`)
  │ (Signature Verification using server-side secret)
  ▼
WebhooksService.receiveWebhook
  │ (Atomic INSERT into payment_webhook_events with status='QUEUED')
  ├─► [On Duplicate Event ID (P2002)]: Return 200 OK 'ignored' immediately (Idempotent)
  ▼
BullMQ Queue (`webhooks`) & WebhookWorker (`webhooks.worker.ts`)
  │ (Asynchronous processing with 3 retries & exponential backoff)
  ▼
WebhooksService.processWebhookEvent
  │ (Loads event, resolves payment & organization from DB)
  ▼
Database Transaction (Serializable Isolation)
  ├─► Update Payment status (CAPTURED / REFUNDED)
  ├─► Update Booking status (CONFIRMED)
  ├─► FinanceService.recordPayment / recordRefund (Immutable double-entry ledger)
  └─► Update PaymentWebhookEvent status (PROCESSED)
  ▼
Domain Events & Audit Trail
  ├─► Events.PAYMENT_CAPTURED / Events.PAYMENT_REFUNDED
  └─► AuditService.record ('webhook:payment_captured_processed')
```

## 3. Webhook Data Model (`PaymentWebhookEvent`)
- **Fields**:
  - `id`: String @id
  - `provider`: String ('RAZORPAY' | 'STRIPE')
  - `providerEventId`: String (Unique gateway event ID)
  - `eventType`: String
  - `signature`: String?
  - `status`: String (`RECEIVED`, `QUEUED`, `PROCESSING`, `PROCESSED`, `IGNORED`, `FAILED`)
  - `paymentId`: String?
  - `organizationId`: String?
  - `payload`: Json?
  - `receivedAt`: DateTime @default(now())
  - `processingStartedAt`: DateTime?
  - `processedAt`: DateTime?
  - `failedAt`: DateTime?
  - `retryCount`: Int @default(0)
  - `lastError`: String?
- **Constraints**:
  - `@@unique([provider, providerEventId])` — Primary idempotency boundary preventing race conditions.

## 4. Razorpay & Stripe Security Verification
- **Raw Request Body**: Verifies signatures using raw request body (`req.rawBody`) against server-side environment secrets (`RAZORPAY_WEBHOOK_SECRET`, `STRIPE_WEBHOOK_SECRET`).
- **Invalid Signatures**: Immediately rejected with 400 Bad Request and logged to audit trail.

## 5. Out-Of-Order Event & Finance Ledger Protection
- **State Machine**: Checks `latestPayment.status` before state transitions.
- **Ledger Idempotency**: `FinanceService.recordPayment` uses `pay_${payment.id}` and `recordRefund` uses `refund_${payment.id}_${amount}` idempotency keys, guaranteeing that even worker retries will never generate duplicate financial ledger entries.

## 6. Admin Operations Console
- **`AdminWebhookLogsScreen`** (`lib/features/admin_dashboard/presentation/screens/admin_webhook_logs_screen.dart`):
  - Filterable log list by status (`PROCESSED`, `FAILED`, `QUEUED`, `IGNORED`) and provider (`RAZORPAY`, `STRIPE`).
  - Webhook Detail Modal displaying processing timeline, retry count, last error trace, and raw JSON payload.
  - "Retry Webhook" action button invoking `POST /api/v1/admin/webhooks/:id/retry`.

## 7. Verification & Test Results
- **Backend Unit Tests**: 25/25 Test Suites Passed (89 total tests passed, including `WebhooksService` & `WebhookWorker` test cases).
- **Prisma Schema & Migration**: `20260905000000_add_webhook_resilience` deployed.
- **NestJS Build**: Succeeded (`nest build`).
- **Flutter Analyze**: 0 issues found (`flutter analyze` clean).
- **Flutter Tests**: Passed.
- **Regression**: Customer V3, Partner Shell, Admin Console, and Redis/BullMQ worker queues remain 100% operational.
