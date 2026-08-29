# PlayHub Phase 55: Slot Engine, Availability Engine & Dynamic Pricing Foundation

## 1. Executive Summary
Phase 55 establishes the core marketplace engines of PlayHub: **Slot Generation**, **Availability Verification**, and **Dynamic Pricing**. This architecture transitions the platform from a simple booking tool to a sophisticated yield-management system capable of handling complex sports facility operations across multiple timezones.

## 2. Slot Engine Architecture
The Slot Engine is a dynamic generator that derives bookable intervals based on:
- **Facility Configuration**: `defaultSlotDuration` (e.g., 60m) and `supportedSlotDurations`.
- **Operating Hours**: Base windows when the venue is open.
- **Constraints**: Existing bookings and availability blocks are subtracted from operating windows.
- **Generation Logic**: Uses a stepping algorithm to carve remaining intervals into fixed-duration slots.

## 3. Availability Engine
The Availability Engine provides high-concurrency safe verification:
- **Multi-Period Support**: Handles multiple opening/closing times per day.
- **Overnight Hours**: Logic supports operating windows spanning across midnight (e.g., 22:00 to 02:00).
- **Timezone Authority**: All calculations are performed in the `Venue.timezone` (e.g., `Asia/Kolkata`).
- **Recurring Blocks**: Supports blocking specific days/times for maintenance or private events.

## 4. Pricing Engine & Dynamic Rules
The server is now the absolute authority for pricing. The client NEVER calculates the price.
- **Interval-Based Pricing**: Calculates total cost by segmenting requested time into 15-minute chunks and matching each against the best rule.
- **Priority Resolution**: Deterministic priority system (`priority` field) ensures that "Peak" or "Holiday" rules override "Base" rules.
- **Pricing Dimensions**:
    - `daysOfWeek`: Different rates for weekends vs weekdays.
    - `startTime` / `endTime`: Peak hour surcharges.
    - `effectiveFrom` / `effectiveTo`: Special date-range pricing (e.g., Festivals).
- **Price Snapshot**: Every booking stores a `priceSnapshot` (JSON breakdown) to ensure historical immutability if rules change later.

## 5. Security & Concurrency
- **Serializable Transactions**: Booking creation uses PostgreSQL `Serializable` isolation level to prevent double-booking.
- **Stale Availability Revalidation**: The backend re-verifies slot availability and re-calculates price immediately before confirming a booking, ignoring potentially stale client-side data.
- **Tenant Isolation**: `OrganizationGuard` ensures partners can only manage rules for facilities they own.

## 6. API Contracts
- `GET /api/v1/organizations/:orgId/availability/facilities/:facilityId?date=...`: Returns slots with prices and breakdown.
- `POST /api/v1/organizations/:orgId/facilities/:facilityId/pricing-rules`: Create rule.
- `POST /api/v1/organizations/:orgId/facilities/:facilityId/blocks`: Create block.

## 7. Performance & Scale
- **Database Indexes**: Optimized indexes on `startTime`, `endTime`, `facilityId`, and `status`.
- **Stateless Calculation**: Slot and price generation is stateless, allowing horizontal scaling of backend nodes.
- **Future Caching**: Strategy documented for caching operating hours and pricing rules in Redis.

## 8. Verification Results
- **Backend Unit Tests**: 62/62 Passed.
- **Concurrency Test**: 10 simultaneous booking attempts for same slot results in exactly 1 success.
- **Emulator Validation**: Verified slot listing with real prices and successful booking flow on Android Emulator.
