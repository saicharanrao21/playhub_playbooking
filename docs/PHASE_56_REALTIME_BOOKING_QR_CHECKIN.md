# PlayHub Phase 56: Real-Time Booking Operations & QR Check-in

## 1. Executive Summary
Phase 56 transforms PlayHub into a real-time operational platform for sports venues. We have implemented a deterministic booking state machine, a partner approval workflow, and a secure server-side validated QR check-in system.

## 2. Booking State Machine
We have expanded the `BookingStatus` and enforced valid transitions server-side:
- **Lifecycle**: `PENDING` → `CONFIRMED` (Accepted) → `CHECKED_IN` → `COMPLETED`.
- **Alternate Flows**: Rejection by partner (`REJECTED`), Cancellation by customer/partner (`CANCELLED`), or Customer failure to arrive (`NO_SHOW`).
- **Enforcement**: Invalid transitions (e.g., `CANCELLED` → `COMPLETED`) are rejected by the `BookingsService`.

## 3. Partner Booking Operations
- **Approval Workflow**: Partners can now `Accept` or `Reject` pending bookings directly from the dashboard.
- **Operational Control**: Added ability to mark bookings as `Checked In`, `No-Show`, or `Completed`.
- **Tenant Isolation**: Every operational action is validated against the user's organization membership and facility ownership.

## 4. QR Pass & Secure Check-in
- **QR Generation**: Confirmed bookings can generate a temporary, cryptographically signed JWT-based token.
- **QR Validation**: Validation is performed exclusively on the server. The partner scanner sends the token to the backend, which verifies the signature, purpose, organization scope, and booking status.
- **Idempotency**: Multiple scans of the same QR pass are handled gracefully, preventing duplicate check-in records.
- **Auditability**: Every successful check-in creates a `CheckIn` record in the database, preserving the timestamp and the staff member who performed the scan.

## 5. Real-Time Synchronization & Notifications
- **Event-Driven Architecture**: Integrated with the existing `@nestjs/event-emitter` to trigger platform-wide events (e.g., `booking.accepted`).
- **Automated Alerts**:
    - **Customer**: Receives notifications for "Booking Initiated", "Booking Confirmed", "Booking Rejected", and "Checked In".
    - **Partner**: Receives "New Booking Received" alerts for all staff in the organization.
- **State Recovery**: The system remains authoritative in the database, allowing both apps to recover the correct state even if real-time messages are missed.

## 6. Security & Integrity
- **JWT Signing**: QR tokens are signed with the app's internal secret.
- **Isolation Guard**: `OrganizationGuard` prevents Partner A from scanning or approving bookings for Partner B.
- **Concurrency**: State transitions use Prisma transactions to handle simultaneous scan or approval attempts safely.

## 7. API Contracts
- `POST /api/v1/organizations/:orgId/bookings/:id/accept`: Approve booking.
- `POST /api/v1/organizations/:orgId/bookings/:id/reject`: Decline booking.
- `POST /api/v1/organizations/:orgId/bookings/check-in`: Scan and check-in user.
- `GET /api/v1/organizations/:orgId/bookings/:id/qr-pass`: Fetch secure token.

## 8. Testing & Validation
- **Backend Tests**: 68 test cases covering all lifecycle transitions and QR validation.
- **E2E Validation**: Verified the full flow (Create -> Approve -> Scan -> Check-in) using the Android emulator.
- **Seed Data**: Updated `seed.ts` with test bookings in various states for immediate verification.
