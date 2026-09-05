# PlayHub Architecture Decision Records (ADRs)

## ADR-001: Flutter Multi-Platform Strategy
- **Status**: Approved
- **Context**: PlayHub requires Customer, Partner, and Admin interfaces across Android, iOS, and Web.
- **Decision**: Use a single Flutter codebase with Riverpod state management and GoRouter, sharing 100% of domain models, networking, and business logic while rendering responsive UI layouts.
- **Consequences**: Eliminates code duplication across platforms; requires careful responsive breakpoint design for desktop vs mobile.

## ADR-002: Modular Monolith Backend Architecture
- **Status**: Approved
- **Context**: Scaling PlayHub to 1M+ users while avoiding the deployment and operational complexity of microservices.
- **Decision**: Build NestJS as a Modular Monolith with clear domain module boundaries (`Auth`, `Venues`, `Bookings`, `Payments`, `Finance`, `Webhooks`, `Queues`, `Redis`).
- **Consequences**: High development speed, single deployment unit, easy local testing, straightforward future microservice extraction if needed.

## ADR-003: PostgreSQL as Single Source of Truth
- **Status**: Approved
- **Context**: Ensuring absolute data integrity for bookings, court availability, and financial ledgers.
- **Decision**: PostgreSQL 15 with Prisma ORM is the authoritative source of truth. Redis and in-memory caches are non-authoritative.
- **Consequences**: Booking transactions and ledger entries execute in PostgreSQL `Serializable` transactions; Redis failures never corrupt state.

## ADR-004: Redis 7 for Caching & Distributed Locks
- **Status**: Approved
- **Context**: Reducing database load on high-frequency read endpoints (venue search, discovery).
- **Decision**: Use Redis 7 with ioredis. Apply `CacheService.getOrSet` with 300s TTL for nearby venue searches and `LockService` for atomic locks.
- **Consequences**: Sub-5ms cache hits for nearby venues; automatic fallback to PostgreSQL if Redis is offline.

## ADR-005: BullMQ Asynchronous Job Processing
- **Status**: Approved
- **Context**: Offloading non-critical tasks (notifications, webhooks, reconciliation, settlements) from HTTP request handlers.
- **Decision**: Use BullMQ queues backed by Redis with exponential backoff retries and idempotent worker handlers.
- **Consequences**: Webhooks acknowledge in <200ms; background workers handle retry resilience without blocking gateways.

## ADR-006: Immutable Double-Entry Ledger for Finance
- **Status**: Approved
- **Context**: Accounting for platform commissions, partner earnings, refunds, and payouts without ledger drift.
- **Decision**: Implement double-entry accounting in `FinancialTransaction` and `LedgerEntry` tables (`Sum(Debits) == Sum(Credits)`).
- **Consequences**: Historical financial entries are immutable; refunds and corrections create new reversal transactions.

## ADR-007: Webhook Idempotency Boundary
- **Status**: Approved
- **Context**: Payment gateways (Razorpay/Stripe) frequently send duplicate or retried webhook events.
- **Decision**: Enforce a unique constraint `@@unique([provider, providerEventId])` on `payment_webhook_events`.
- **Consequences**: Concurrent or duplicate webhook deliveries trigger database unique constraint check (`P2002`) and return 200 OK without duplicate ledger entry creation.

## ADR-008: Server-Authoritative Dynamic Pricing Engine
- **Status**: Approved
- **Context**: Partner venues configure peak hour surcharges, day-of-week rates, and duration discounts.
- **Decision**: All price calculations are computed server-side in NestJS `PricingService`. Flutter client displays prices calculated by the server.
- **Consequences**: Prevents client-side price tampering or stale pricing calculations during checkout.

## ADR-009: Server-Authoritative Slot Availability
- **Status**: Approved
- **Context**: Preventing double bookings during high-demand booking surges.
- **Decision**: `BookingsService` reserves slots inside a PostgreSQL `Serializable` transaction.
- **Consequences**: Guarantees zero double bookings even during concurrent booking spikes.

## ADR-010: Organization Tenant Isolation
- **Status**: Approved
- **Context**: Protecting partner business data, venues, bookings, and payout records across multi-tenant organizations.
- **Decision**: Require `x-organization-id` header on partner endpoints and enforce `OrganizationGuard` to verify user membership.
- **Consequences**: Blocks IDOR and cross-tenant data access attempts.

## ADR-011: Web-First Admin Operations Console Architecture
- **Status**: Approved
- **Context**: Internal operations teams require dense, information-rich interfaces for KYC review, financial reconciliation, and webhook logs.
- **Decision**: Design the Admin Console for desktop/web viewports with responsive fallback for mobile screens.
- **Consequences**: Maximizes operational productivity for platform administrators.

## ADR-012: Shared Core Domain with Product-Specific UX Design Tokens
- **Status**: Approved
- **Context**: Customer, Partner, and Admin apps represent different user contexts but belong to the same brand.
- **Decision**: Share core models and design system tokens (colors, typography, spacing, radius) while building tailored UX layouts for each product surface.
- **Consequences**: Consistent brand identity with UX layouts optimized for each persona's task requirements.
