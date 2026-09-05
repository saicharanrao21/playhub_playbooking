# PlayHub Backend Architecture (NestJS Modular Monolith)

## 1. Directory & Module Structure
The backend is structured as a **Modular Monolith** in NestJS:

```
backend/src/
├── main.ts                     # Application entry point with rawBody parser & Swagger
├── app.module.ts               # Root module registering global configuration & feature modules
├── common/
│   ├── config/                 # Env validation schema
│   ├── constants/              # System events, permissions, role names
│   ├── decorators/             # @CurrentUser, @OrganizationContext, @Public, @RequirePermission
│   ├── dto/                    # PaginationDto
│   ├── filters/                # ApiExceptionFilter
│   ├── guards/                 # JwtAuthGuard, OrganizationGuard, PlatformAdminGuard, PermissionsGuard
│   ├── interceptors/           # AuditInterceptor
│   ├── middleware/             # RequestIdMiddleware
│   └── services/               # AuditService, GeocodingService
├── redis/
│   ├── redis.service.ts        # ioredis connection manager
│   ├── cache.service.ts        # getOrSet, delPattern caching abstraction
│   └── lock.service.ts         # Atomic distributed locks (SET NX PX + Lua release)
├── queues/
│   ├── queue.service.ts        # Centralized BullMQ queue manager & nightly reconciliation job
│   └── workers/                # NotificationWorker, ReconciliationWorker, SettlementWorker, PayoutWorker
├── webhooks/
│   ├── webhooks.service.ts     # Razorpay/Stripe signature verification & async BullMQ enqueuing
│   ├── webhooks.worker.ts      # Async webhook worker executing payment & finance state transitions
│   ├── webhooks.controller.ts  # Fast ACK receiver endpoints (<200ms)
│   └── admin-webhooks.controller.ts # Admin webhook log viewer & retry endpoint
├── finance/
│   ├── finance.service.ts      # Double-entry ledger engine & financial summaries
│   ├── settlement.service.ts   # Settlement batch generation
│   ├── payout.service.ts       # Payout initiation & bank transfer completion/failure handling
│   └── reconciliation.service.ts # Multi-account reconciliation engine
├── venues/                     # Venue CRUD & radius search with bounding-box index filtering
├── availability/               # Slot engine & dynamic pricing rules
├── bookings/                   # Transactional slot reservation & QR ticket validation
├── payments/                   # Razorpay/Stripe checkout SDK integration
├── notifications/              # Multi-channel notification dispatch
└── admin/                      # Internal Operations Console APIs
```

---

## 2. Distributed Caching & Locking Strategy

```
[ Request ] ──► [ CacheService.getOrSet('venues:nearby:...') ]
                      │
            ┌─────────┴─────────┐
            ▼                   ▼
      (Cache Hit)          (Cache Miss)
      [ Return JSON ]      [ Query PostgreSQL Index ]
                           [ Compute Haversine Dist ]
                           [ Store in Redis (300s)  ]
                           [ Return JSON ]
```

- **Cache Ownership**: PostgreSQL is the single source of truth. Caches store serializable JSON with strict TTLs (300s for venue search).
- **Cache Invalidation**: Mutations (`createVenue`, `updateVenue`) execute `cacheService.delPattern('venues:*')` to instantly purge stale cache items.
- **Distributed Locking**: `LockService.acquireLock('slot:res:123')` prevents race conditions across horizontal instances.

---

## 3. Asynchronous BullMQ Queue Architecture

```
[ Domain Action ] ──► [ QueueService.addJob ]
                             │
                             ▼
                    ┌─────────────────┐
                    │ BullMQ Queue    │
                    │  (Redis-backed) │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ WebhookWorker / │
                    │ NotificationWkr │
                    └────────┬────────┘
                             │
                             ▼
                    [ Execute Transaction & Emit Event ]
```

- **Core Queues**: `notifications`, `finance`, `reconciliation`, `settlement`, `webhooks`.
- **Nightly Reconciliation**: Scheduled BullMQ job (`reconciliation_nightly_${todayStr}`) registered on startup, executing full ledger audits every 24 hours.

---

## 4. Middleware & Error Handling Pipeline
1. `RequestIdMiddleware`: Generates or passes `x-request-id` header for end-to-end trace correlation.
2. `ThrottlerGuard`: Limits abusive requests (100 req / min per IP).
3. `ApiExceptionFilter`: Formats all uncaught exceptions into standard JSON error responses.
4. `AuditInterceptor`: Automatically logs user actions to `audit_logs` table.
