# Architecture Overview

PlayHub is designed as a modular monolith with a focus on security, consistency, and scalability.

## 🏗️ Core Stack
- **Frontend**: Flutter (Cross-platform UI)
- **Backend**: NestJS (Node.js framework)
- **Database**: PostgreSQL (Relational persistence)
- **ORM**: Prisma (Type-safe database access)
- **State Management**: Riverpod (Flutter)

## 🔒 Security Model
1. **Multi-Tenancy**: Strict isolation via `organizationId` on all database records and guard-level enforcement.
2. **Authentication**: E2E JWT-based auth with rotating refresh tokens and reuse detection.
3. **Authorization**: RBAC (Role-Based Access Control) using membership-linked roles and permissions.
4. **Rate Limiting**: Global and endpoint-specific throttling to prevent abuse.

## 📅 Booking Engine
- **Concurrency**: Leverages PostgreSQL `Serializable` transactions and `EXCLUDE` constraints to prevent overlapping reservations.
- **Availability**: Dynamically calculated by subtracting closures, blocks, and active bookings from venue operating hours.
- **Lifecycle**: Managed via an internal state machine (Pending, Confirmed, Cancelled, Completed).

## 💳 Payment Foundation
- **Abstraction**: `IPaymentProvider` interface allows swapping between Razorpay and Stripe.
- **Verification**: Signature-based authoritative confirmation (no client-side trust).
- **Consistency**: Atomic updates between payment capture and booking confirmation.

## 📡 Communication
- **Events**: Decoupled internal event system (`EventEmitter2`).
- **Notifications**: Centralized module for user alerts linked to booking lifecycle changes.
