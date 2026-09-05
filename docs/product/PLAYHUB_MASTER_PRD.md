# PlayHub Master Product Requirements Document (PRD)

## 1. Executive Summary & Vision
PlayHub is an enterprise-grade, high-scale sports and activity marketplace platform designed to connect sports enthusiasts ("Customers"), venue and court operators ("Partners"), and internal operations teams ("Platform Admins").

- **Vision**: To become the premier digital infrastructure for recreational sports, court bookings, tournaments, and social matchmaking across India and emerging global markets.
- **Mission**: Provide instant, transparent, location-aware court discovery and booking for customers while empowering sports venue owners with automated inventory management, dynamic pricing, fast check-in, and double-entry financial settlement.
- **Scale Target**: Built to support 1M+ active customers, 10,000+ partner venue organizations, 50,000+ courts/facilities, and millions of concurrent booking transactions.

---

## 2. User Personas & Ecosystem
PlayHub governs three primary application surfaces with 7 distinct user personas:

### A. Customer Application Surface
1. **Casual Player ("Aarav")**: Wants quick 1-tap booking for weekend cricket or badminton near his location. Prioritizes distance, pricing, and court photos.
2. **Community Host ("Rhea")**: Organizes open friendly matches or tournaments. Wants to host games, invite players, track RSVPs, and collect split payments.

### B. Partner / Owner Application Surface
3. **Venue Owner / Operator ("Vikram")**: Owns multi-court sports complexes (box cricket, turf football, badminton courts). Requires multi-venue management, custom pricing rules, payout tracking, and KYC/banking verification.
4. **On-Ground Court Manager ("Suresh")**: Manages daily court operations, staff check-ins, QR ticket scanning, and walk-in slot locking.

### C. Internal Operations Console Surface
5. **Platform Admin**: Oversees platform health, global venue approvals, city/category configurations, and systemic system settings.
6. **Operations & Support Admin**: Reviews partner KYC submissions, handles dispute tickets, and investigates audit logs.
7. **Finance & Compliance Admin**: Audits double-entry ledgers, manages commission rules, generates settlements, and handles manual partner adjustments or payout retries.

---

## 3. Marketplace & Business Model
PlayHub operates a dual-sided sports marketplace model with platform-governed financial clearing:

```
[ Customer ] ──(Payment)──► [ PlayHub Payment Clearing ]
                                     │
                    ┌────────────────┴────────────────┐
                    ▼                                 ▼
         [ Platform Revenue ]               [ Partner Payable ]
         (Commission % + Fee)               (Net Venue Earnings)
                                                      │
                                           (Settlement & Payout)
                                                      ▼
                                            [ Partner Bank Account ]
```

- **Commission Structure**: Configurable global default (e.g. 10.0% + fixed fee) with organization-specific overrides and historical snapshotting.
- **Settlement Lifecycle**: `OPEN` → `PROCESSING` → `FINALIZED` → `PAID`.
- **Double-Entry Financial Accounting**: All payments, refunds, commissions, adjustments, and payouts are tracked in immutable double-entry ledger entries.

---

## 4. Key Performance Indicators (KPIs)
| KPI Category | Target Metric | SLA / Threshold |
| :--- | :--- | :--- |
| **User Conversion** | Search-to-Booking Conversion Rate | > 18% |
| **Venue Activation** | KYC Submission to Approval Time | < 24 Hours |
| **Venue Occupancy** | Average Prime-Time Court Utilization | > 72% |
| **System Reliability** | Booking API & Payment Gateway Availability | 99.95% Uptime |
| **Financial Integrity** | Ledger Discrepancy Count | **0 Discrepancies** |
| **Payment Success** | Payment Gateway Capture Rate | > 96% |
| **Check-in Efficiency** | QR Ticket Scan Verification Latency | < 1.5 Seconds |

---

## 5. Domain Functional Requirements Map
The following table details the functional scope across all platform domains, linking business requirements to technical domain owners in the PlayHub codebase:

| Domain | Functional Requirement | Dominant Persona | System Module |
| :--- | :--- | :--- | :--- |
| **Identity & Access** | JWT Auth, Refresh Tokens, Email/Phone Verification, RBAC | All Personas | `AuthModule` / `UsersModule` |
| **Partner Onboarding** | Org Creation, KYC (PAN/GST/Bank Info), Admin Review Queue | Partner / Admin | `OrganizationsModule` / `AdminModule` |
| **Venue Management** | Multi-Venue Hierarchy, Operating Hours, Address & Geocoding | Partner / Admin | `VenuesModule` / `CitiesModule` |
| **Facility & Inventory** | Multi-court hierarchy, capacity, default slot durations | Partner | `FacilitiesModule` |
| **Availability Engine** | Real-time slot generator, maintenance locks, recurring blocks | Customer / Partner | `AvailabilityModule` |
| **Dynamic Pricing** | Peak hour surcharges, day-of-week rules, priority rules | Partner | `PricingService` |
| **Location & Discovery** | GPS detection, radius search (2-50km), OpenStreetMap view | Customer | `DiscoveryModule` / `GeocodingService` |
| **Search Intelligence** | Debounced text query, sports category chips, distance sorting | Customer | `SearchScreen` / `VenuesService` |
| **Booking Engine** | 1-tap court booking, idempotency, atomic slot reservation | Customer / Partner | `BookingsModule` |
| **Payment & Webhooks** | Razorpay/Stripe checkout, rawBody signature verification, BullMQ | Customer / Gateway | `PaymentsModule` / `WebhooksModule` |
| **Double-Entry Ledger** | Immutable financial transactions, credit/debit ledger entries | Finance Admin | `FinanceModule` |
| **Settlement & Payout** | Settlement generation, payout requests, bank transfer retries | Partner / Admin | `SettlementService` / `PayoutService` |
| **QR Check-in** | Single-use QR ticket generation, staff camera scanner | Customer / Staff | `CheckInService` / `MobileScanner` |
| **Notifications** | Multi-channel push/SMS alerts, event-driven BullMQ workers | Customer / Partner | `NotificationsModule` / `QueueModule` |
| **Audit & Security** | Immutable admin audit logs, organization tenant isolation | All Admins | `AuditService` / `OrganizationGuard` |
