# PlayHub Phase 57: Partner Business Finance, Ledger & Payout Foundation

## 1. Executive Summary
Phase 57 establishes a high-integrity financial foundation for PlayHub. We have moved from a simple "revenue display" to a **Double-Entry Ledger Architecture**. This ensures that every rupee on the platform is accounted for, immutable, and auditable, preparing PlayHub for 1M+ users and complex multi-vendor operations.

## 2. Financial Architecture
We have implemented a **Double-Entry Ledger** system where every financial event creates a `FinancialTransaction` and exactly balanced `LedgerEntry` records.
- **Asset Accounts**: `PAYMENT_CLEARING` (Platform bank/gateway holdings).
- **Liability Accounts**: `PARTNER_PAYABLE` (Owed to the sports venue).
- **Revenue Accounts**: `PLATFORM_REVENUE` (Collected commissions).

## 3. Booking Financial Events
- **Automatic Triggers**: When a payment is captured via Razorpay/Stripe, an event is emitted.
- **Ledger Recording**: The `FinanceService` listens to these events and atomically records the Gross Amount, Platform Commission, and Partner Net Earnings.
- **Idempotency**: All financial recordings are protected by strict idempotency keys (`pay_{paymentId}`).

## 4. Commission Engine
- **Configurable Fees**: Introduced `CommissionConfig` model.
- **Tiered Resolution**: Supports global default commissions and organization-specific overrides.
- **Snapshots**: The exact commission percentage and amount are snapshotted into the `FinancialTransaction` metadata at the time of booking.

## 5. Partner Wallet & Balance
- **Ledger-Derived**: The balance shown to partners is NOT a mutable column. It is computed in real-time by aggregating the `PARTNER_PAYABLE` ledger entries (Credits - Debits).
- **High Integrity**: This prevents balance drift and ensures that the total platform liability always matches the sum of partner balances.

## 6. Settlement & Payout Model
- **Settlement**: Foundation for aggregating transactions into "Ready for Payout" batches.
- **Payouts**: Secure records for bank transfers, tracking statuses from `PENDING` to `COMPLETED` or `FAILED`.
- **Masking**: Sensitive bank details are masked in the UI to protect partner privacy.

## 7. Partner Finance UI
- **Dashboard**: High-level overview of Available Balance, Settled, and Pending amounts.
- **Transactions**: Searchable and filterable list of all money movements (Payments, Commissions, Payouts).
- **Transparency**: Detailed breakdown of every booking, showing Gross vs Net.

## 8. Security & Scale
- **Tenant Isolation**: Partners can only access financial data belonging to their organization.
- **Precision**: Using PostgreSQL `DECIMAL(12,2)` for zero-precision loss during calculations.
- **Horizontal Scaling**: Finance logic is stateless and uses database transactions for concurrency control.

## 9. API Contracts
- `GET /api/v1/organizations/:orgId/finance/balance`: Fetch real-time wallet balance.
- `GET /api/v1/organizations/:orgId/finance/transactions`: Paginated financial ledger.

## 10. Verification
- **Backend Tests**: 70+ test cases passed, including double-entry balancing and commission resolution.
- **Emulator Validation**: Verified real-time balance updates in the Partner App after mock payment captures.
