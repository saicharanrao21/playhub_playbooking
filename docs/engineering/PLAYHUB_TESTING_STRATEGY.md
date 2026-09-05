# PlayHub Enterprise Testing Strategy

## 1. Testing Pyramid & Quality Gates

```
                 ▲
                / \       E2E Smoke Tests (Flutter + Backend)
               /   \      [ 5% - Core Booking & Payout Journey ]
              /-----\
             /       \    Integration Tests (NestJS + Prisma + Redis + BullMQ)
            /---------\   [ 25% - Webhooks, Ledger, Availability, Queues ]
           /           \
          /-------------\ Unit Tests (Jest & Flutter Test)
         /───────────────\[ 70% - Services, Math, Formatters, State Notifiers ]
```

---

## 2. Automated Quality Verification Commands

Before declaring any implementation phase complete, all of the following quality gates MUST pass:

```bash
# 1. Flutter Static Analysis (0 Warnings / 0 Errors required)
flutter analyze

# 2. Flutter Unit & Widget Tests
flutter test

# 3. Flutter Android Build
flutter build apk --debug

# 4. Backend Jest Unit & Integration Tests (100% Pass)
cd backend && npm test -- --runInBand

# 5. NestJS Production Compilation
cd backend && npm run build

# 6. Prisma Schema Validation
cd backend && npx prisma validate
```

---

## 3. Mandatory Domain Test Scenarios
- **Booking Concurrency**: Double-booking race condition test ensuring only 1 booking succeeds.
- **Webhook Idempotency**: Duplicate webhook POST request handling ensuring 1 ledger record.
- **Double-Entry Ledger Balance**: `Sum(Debits) == Sum(Credits)` for payments and refunds.
- **GPS Radius Search**: Haversine distance calculations and bounding-box bounding checks.
- **KYC Payout Restriction**: Payout request rejection when KYC status is not `APPROVED`.
