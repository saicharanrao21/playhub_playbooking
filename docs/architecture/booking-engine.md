# Booking Engine Architecture

## Overview
The PlayHub Booking Engine is responsible for creating and managing facility reservations. It ensures that every booking is valid according to operational rules and protected against double-booking in concurrent environments.

## Booking Lifecycle
- **PENDING:** Initial state (not used in current direct-confirmation implementation but supported in schema).
- **CONFIRMED:** The reservation is active and blocks availability.
- **CANCELLED:** The reservation is voided and no longer blocks availability.
- **COMPLETED:** The event time has passed.

## Concurrency Strategy
PlayHub uses a **Transactional Check-then-Act** strategy with Prisma:
1. **Transaction Start:** All operations happen within a database transaction.
2. **Conflict Check:** Query for any existing `CONFIRMED` or `PENDING` bookings for the same `facilityId` that overlap the requested `[start, end)` interval.
3. **Availability Validation:** Verify that the requested interval fits entirely within the facility's available operating hours (minus closures and blocks).
4. **Creation:** If both checks pass, the booking is created.

### Overlap Formula
Two intervals `[A.start, A.end)` and `[B.start, B.end)` overlap if:
`A.start < B.end AND B.start < A.end`

## Tenant Isolation
- Every booking is strictly tied to an `organizationId`.
- The `organizationId` is derived from the verified JWT context, never trusted from the client request body.
- All lookups use composite filters ensuring a user can only interact with bookings within their organization.

## Timezone Authority
- The **Venue Timezone** is the source of truth for interpreting the requested date.
- Stored timestamps are UTC, but validation against operating hours happens by converting the requested time to the venue's local timezone.

## Audit Logging
Important mutations (Creation, Cancellation) are automatically captured by the global `AuditInterceptor` for traceability.
