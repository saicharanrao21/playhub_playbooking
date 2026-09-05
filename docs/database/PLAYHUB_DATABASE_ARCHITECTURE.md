# PlayHub Database Architecture (PostgreSQL & Prisma ORM)

## 1. Domain ER Diagram & Entity Overview

```
[ User ] ◄─── (1:N) ─── [ Membership ] ─── (N:1) ───► [ Organization ]
                                                               │
                                         ┌─────────────────────┴─────────────────────┐
                                         ▼                                           ▼
                                    [ Business ]                         [ FinancialTransaction ]
                                         │                                           │
                                         ▼                                           ▼
                                     [ Venue ]                                [ LedgerEntry ]
                                         │
                                         ▼
                                    [ Facility ]
                                         │
                                         ▼
                                     [ Booking ] ◄─── (1:N) ─── [ Payment ]
```

---

## 2. Table Specifications & Indexes

### A. `venues`
- **Purpose**: Physical sports complexes & turfs.
- **Indexes**:
  - `@@index([businessId])`
  - `@@index([cityId])`
  - `@@index([status])`
  - `@@index([latitude, longitude])`
  - `@@index([status, latitude, longitude])` — Bounding-box spatial search index.

### B. `payment_webhook_events`
- **Purpose**: Gateway webhook persistence & deduplication.
- **Indexes & Constraints**:
  - `@@unique([provider, providerEventId])` — Primary idempotency constraint.
  - `@@index([status])`
  - `@@index([paymentId])`
  - `@@index([organizationId])`
  - `@@index([createdAt])`

### C. `financial_transactions` & `ledger_entries`
- **Purpose**: Double-entry financial accounting.
- **Indexes**:
  - `financial_transactions`: `@@index([organizationId])`, `@@index([bookingId])`, `@@index([paymentId])`, `@@index([type])`, `@@index([reversalOfId])`.
  - `ledger_entries`: `@@index([financialTransactionId])`, `@@index([organizationId])`, `@@index([account])`.

---

## 3. Immutability & Financial Accounting Rules
1. **Financial Records are Immutable**: `financial_transactions` and `ledger_entries` rows must NEVER be deleted or updated.
2. **Reversals via New Transactions**: Refunds or corrections create NEW rows of type `REFUND` or `ADJUSTMENT` linked via `reversalOfId`.
3. **Double-Entry Constraint**:
   ```sql
   SUM(debit) = SUM(credit)
   ```
   for every `financialTransactionId`.
