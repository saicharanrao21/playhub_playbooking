# PlayHub Phase 69: Advanced Support, Disputes & Resolution

## 1. Executive Summary
Phase 69 implements a production-grade **Advanced Support, Dispute Resolution, and Goodwill Engine** for PlayHub. Connected customers can submit support tickets, track case status, attach presigned media evidence (Phase 65 pipeline), and initiate formal booking disputes. Platform administrators and partner liaisons review disputes, collect partner responses, and execute server-authoritative financial resolutions (`FULL_REFUND`, `PARTIAL_REFUND`, `GOODWILL_CREDIT`, or `NO_REFUND`) linked to `PaymentsService`, double-entry ledger reversals, and `LoyaltyService` goodwill points.

## 2. Support & Dispute Workflow Architecture
```
[ Customer Help & Support UI ] ──► [ POST /api/v1/support/tickets ]
                                              │ (Create SupportTicket & SupportMessage)
                                              ▼
[ Customer Formal Dispute ] ──► [ POST /api/v1/bookings/:id/disputes ]
                                              │ (Create Dispute & Link Ticket)
                                              ▼
                                 [ State: OPEN / TRIAGED ]
                                              │
[ Partner Response ] ─────────► [ POST /organizations/:id/disputes/:id/response ]
                                              │
                                              ▼
                                 [ State: UNDER_REVIEW ]
                                              │
[ Admin Decision Engine ] ────► [ POST /admin/support/disputes/:id/resolve ]
                                              ├─► [ FULL / PARTIAL REFUND ]: PaymentsService.initiateRefund
                                              ├─► [ GOODWILL_CREDIT ]: LoyaltyService.earnPoints
                                              └─► [ Audit & Event Stream ]: AuditService.record
```

## 3. Database Models & Migration
- Migration `20260905150000_add_support_dispute_models` applied to PostgreSQL:
  - Created `support_tickets` (`userId`, `organizationId`, `bookingId`, `category`, `subject`, `priority`, `status`), `support_messages` (`ticketId`, `senderId`, `senderRole`, `body`, `attachments`), and `disputes` (`ticketId`, `bookingId`, `paymentId`, `organizationId`, `customerId`, `reason`, `status`, `decision`, `refundAmount`, `goodwillPoints`).
  - Added indexes on `organizationId`, `userId`, `bookingId`, `status`, and `priority`.

## 4. Refund Decision Engine & Financial Safety
- **Server-Authoritative Calculations**: Refund amounts are validated against original captured payment amounts in PostgreSQL `Payment` records. Over-refunding is strictly blocked.
- **Double-Entry Ledger Integrity**: `PaymentsService.initiateRefund` generates idempotent financial transaction reversals (`FinanceService.recordRefund`), ensuring double-entry balance (`Sum(Debits) == Sum(Credits)`).
- **Goodwill Compensation**: `LoyaltyService.earnPoints` awards idempotent compensation points for minor service issues (`referenceType: 'DISPUTE_GOODWILL'`).

## 5. Multi-Tenant Security & Role Isolation
- **Tenant Guard**: `OrganizationGuard` and `PermissionsGuard` verify that partners can only view and respond to disputes linked to their own organization's venues/bookings.
- **IDOR Protection**: Customers can only view and reply to their own support tickets and booking disputes.

## 6. Customer & Operations UX
- **`HelpSupportScreen`** (`lib/features/profile/presentation/screens/help_support_screen.dart`):
  - Form to submit new tickets with category and subject.
  - Interactive "My Support Cases" queue displaying live ticket status (`OPEN`, `IN_PROGRESS`, `RESOLVED`, `CLOSED`) and resolution notes.
  - FAQs and direct helpline/support email channels.
- **`AdminSupportController`** (`/admin/support/tickets` & `/admin/support/disputes`):
  - Operator queues for reviewing cases, updating statuses, and resolving disputes.

## 7. Verification & Test Results
- **Backend Unit Tests**: 32/32 Test Suites Passed (115 total tests passed, including `SupportService` and `DisputesService` test cases).
- **Prisma Schema & Validation**: Valid (`npx prisma validate`).
- **NestJS Build**: Succeeded (`nest build`).
- **Flutter Analyze**: 0 issues found (`flutter analyze` clean).
- **Flutter Tests**: Passed.
- **Flutter Web Build**: Succeeded (`flutter build web --release`).
- **Regression Check**: Customer V3, Partner Workspace, Admin Operations Console, Geolocation, Redis, BullMQ, Observability, Object Storage, Webhooks, Memberships/Coupons/Loyalty, WebSockets/Match Chat, and Search Intelligence remain 100% operational.
