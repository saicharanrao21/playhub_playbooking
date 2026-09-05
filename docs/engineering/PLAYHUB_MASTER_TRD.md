# PlayHub Master Technical Requirements Document (TRD)

## 1. System Architecture Principles
PlayHub is engineered as a **Modular Monolith Backend** paired with a **Multi-Platform Flutter Client Application**, backed by **PostgreSQL** (Source of Truth), **Redis 7** (Caching & Distributed Locks), and **BullMQ** (Asynchronous Job Processing).

```
┌────────────────────────────────────────────────────────────────────────┐
│                        FLUTTER CROSS-PLATFORM CLIENT                  │
│               [ Android APK ]   [ iOS App ]   [ Web PWA ]              │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ HTTPS / REST (JSON)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                     NESTJS BACKEND MODULAR MONOLITH                    │
│   ┌───────────────┐   ┌───────────────┐   ┌────────────────────────┐   │
│   │ Auth & Users  │   │ Venues & Slots│   │ Bookings & Check-in    │   │
│   └───────────────┘   └───────────────┘   └────────────────────────┘   │
│   ┌───────────────┐   ┌───────────────┐   ┌────────────────────────┐   │
│   │  Webhooks     │   │ Finance Ledger│   │ Admin Operations       │   │
│   └───────┬───────┘   └───────┬───────┘   └────────────────────────┘   │
└───────────┼───────────────────┼────────────────────────────────────────┘
            │                   │
            ▼                   ▼
┌──────────────────┐    ┌──────────────────┐    ┌────────────────────────┐
│  Redis 7 Cache   │    │ BullMQ Workers   │    │ PostgreSQL 15 Database │
│ (playhub:cache:) │    │(notifications,   │    │ (Prisma ORM Source of  │
│ (playhub:lock:)  │    │ webhooks, etc.)  │    │  Truth)                │
└──────────────────┘    └──────────────────┘    └────────────────────────┘
```

### Core Technical Directives:
1. **PostgreSQL as Single Source of Truth**: Redis and in-memory caches are non-authoritative. Database state and financial transactions are strictly persisted in PostgreSQL using Prisma ORM.
2. **Tenant Isolation**: Every partner resource is scoped to an `organizationId`. Cross-tenant data access is blocked by NestJS `OrganizationGuard`.
3. **Double-Entry Financial Accounting**: Money movement generates balanced `LedgerEntry` records (`Sum(Debits) == Sum(Credits)`). Historical financial entries are immutable.
4. **Idempotency & Concurrency Control**: Critical state transitions (bookings, payments, webhooks, payouts) use unique idempotency keys and `Serializable` database isolation.

---

## 2. Technology Stack & Dependencies

### Backend Stack:
- **Framework**: NestJS v10 (Node.js 20 LTS)
- **ORM / Database**: Prisma ORM v5.22, PostgreSQL 15 (Alpine)
- **Caching & Locks**: Redis v7 (Alpine), `ioredis` v5
- **Background Queues**: BullMQ v5
- **Security**: Passport.js, JWT, bcrypt, Helmet, Throttler
- **Payments**: Razorpay Node SDK, Stripe Node SDK

### Frontend Stack:
- **Framework**: Flutter 3.24+ (Dart 3.5+)
- **State Management**: Flutter Riverpod v2.5
- **Navigation**: GoRouter v14
- **Maps & Geolocation**: `flutter_map` v7 (OpenStreetMap tiles), `latlong2`, `geolocator` v13
- **Networking**: Dio v5 (with secure storage token interceptor)
- **Scanner**: `mobile_scanner` v5

---

## 3. Non-Functional Requirements & Technical SLAs

| Metric | Requirement / Target | Technical Mechanism |
| :--- | :--- | :--- |
| **API Response Time (p95)** | < 150 ms | Redis caching (`venues:nearby:*`) + Bounding Box SQL indexes |
| **Webhook Response SLA** | < 200 ms | Async BullMQ queue offloading (`status: QUEUED`) |
| **Booking Transaction SLA** | < 800 ms | Serializable PostgreSQL slot reservation |
| **System Availability** | 99.95% Uptime | Multi-stage Docker deployment, Render readiness health probes |
| **Database Precision** | 2 Decimal Places (`12,2`) | PostgreSQL `DECIMAL` types for currency |
| **Max Search Radius** | 100 km | Bounded `NearbyVenuesQueryDto` validation |
| **Max Page Size** | 50 Items | `PaginationDto` enforcement |

---

## 4. Environment & Deployment Configuration

PlayHub supports three deployment targets using standardized environment variables:

```bash
# Core Database Connection
DATABASE_URL="postgresql://playhub:password@localhost:5432/playhub?schema=public"

# Redis & Queues
REDIS_URL="redis://localhost:6379"

# Security Secrets
JWT_ACCESS_SECRET="min-32-character-access-token-secret-key"
JWT_REFRESH_SECRET="min-32-character-refresh-token-secret-key"

# Payment Webhook Secrets
RAZORPAY_WEBHOOK_SECRET="rzp_webhook_secret_key"
STRIPE_WEBHOOK_SECRET="whsec_stripe_secret_key"

# Application Settings
NODE_ENV="production"
PORT=3000
API_PREFIX="api/v1"
```
