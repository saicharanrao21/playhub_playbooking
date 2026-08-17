# Target Architecture - PlayHub Platform

## Vision
PlayHub is a scalable platform for sports and recreation venue booking, supporting customers, business owners, and administrators.

## High-Level System Components
- **Customer App (Flutter):** Mobile and Web interface for searching and booking venues.
- **Business Platform (Flutter/Web):** Interface for venue owners to manage availability, bookings, and payments.
- **Admin / Operations (Flutter/Web):** Internal tool for PlayHub staff to manage the platform.
- **Backend API:** Centralized server authoritative logic (Node.js/Go/Python).
- **Database:** Transactional database (PostgreSQL) for persistence.
- **Payments:** Integration with Stripe/Razorpay for secure transactions.
- **Notifications:** Push notifications, SMS, and Email (Firebase Cloud Messaging/Twilio/SendGrid).
- **Analytics:** Data tracking for business insights.
- **Security:** OAuth2/OpenID Connect for authentication and RBAC for authorization.

## Intended Flutter Directory Structure
```text
lib/
│
├── app/
│   ├── bootstrap/      # App initialization logic
│   ├── router/         # Navigation configuration
│   └── app.dart        # Root widget
│
├── core/
│   ├── config/         # App configuration and environment variables
│   ├── constants/      # Global constants
│   ├── errors/         # Error handling and custom exceptions
│   ├── logging/        # Centralized logging
│   ├── networking/     # API client and network logic
│   ├── security/       # Token management and encryption
│   ├── storage/        # Local persistence (Hive/Isar)
│   └── analytics/      # Tracking and metrics
│
├── features/
│   ├── auth/           # Login, Signup, OTP, Password recovery
│   ├── onboarding/     # First-time user experience
│   ├── home/           # Landing page and discovery
│   ├── search/         # Venue search and filtering
│   ├── venues/         # Venue profiles and details
│   ├── availability/   # Real-time slot management
│   ├── booking/        # Booking flow and checkout
│   ├── payments/       # Payment history and verification
│   ├── profile/        # User settings and personal info
│   └── notifications/  # In-app notification center
│
└── shared/
    ├── components/     # Reusable UI widgets
    ├── models/         # Shared data models (Entities)
    └── extensions/     # Dart extension methods
```

## Architectural Principles

### 1. Scalability
The architecture must support growth from 100 to 1,000,000+ users. This is achieved through modularity and clear domain boundaries.

### 2. Security (Server-Side Authority)
The client application is NEVER trusted.
- All sensitive operations (booking, pricing, payments) MUST be verified by the server.
- Proper authentication and authorization (RBAC) are mandatory.
- Tokens must be stored securely.

### 3. Booking Reliability
The booking engine must handle:
- **Double Booking Prevention:** Atomic transactions at the database level.
- **Race Conditions:** Locking mechanisms for concurrent requests.
- **Payment Verification:** "Hold" mechanism before final confirmation.

### 4. Financial Integrity
- All financial operations must be auditable.
- Clear separation between Payment Attempts, Transactions, and Refunds.
- Reconciliation processes must be supported.

### 5. Multi-Tenancy
- Robust support for Organizations (Businesses) and Teams (Staff).
- Granular permissions (Admin, Manager, Staff) instead of simple boolean flags.

## Clean Architecture Guidance
- **Data Layer:** Repository implementations, API clients, DTOs.
- **Domain Layer:** Entities, Use Cases (Interactors), Repository Interfaces.
- **Presentation Layer:** ViewModels/Controllers (Riverpod), UI Screens, Widgets.
