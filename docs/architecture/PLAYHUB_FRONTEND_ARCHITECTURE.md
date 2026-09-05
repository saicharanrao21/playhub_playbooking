# PlayHub Frontend Architecture (Flutter Multi-Platform Strategy)

## 1. Directory Structure & Feature Organization
PlayHub's Flutter codebase is organized using a **Feature-First Clean Architecture**:

```
lib/
├── app/
│   ├── bootstrap/      # App container initialization & global Riverpod overrides
│   ├── config/         # Environment & theme configuration
│   └── router/         # GoRouter path definitions & auth guards
├── core/
│   ├── logging/        # AppLogger structured logging wrapper
│   ├── models/         # Cross-domain shared models (User, Venue, Booking, etc.)
│   ├── networking/     # Dio IApiClient & HTTP interceptors
│   ├── providers/      # Core singleton repository providers
│   ├── repositories/   # Base repository interfaces & implementations
│   ├── security/       # AuthProvider & RBAC permission helpers
│   └── services/       # LocationService, SecureStorage
├── features/
│   ├── admin_dashboard/ # Operations Console screens, providers & repositories
│   ├── availability/   # Court availability calendar & slot selection
│   ├── bookings/       # Customer booking list & details
│   ├── business_dashboard/ # Legacy business management screens
│   ├── home/           # Customer V3 HomeScreen & discovery
│   ├── notifications/  # User notification list & preferences
│   ├── partner/        # Dedicated Partner workspace, onboarding, KYC & finance
│   ├── profile/        # User profile, wallet & security settings
│   ├── search/         # Location-aware search, filters & MapViewScreen
│   ├── tournaments/    # Tournament discovery & details
│   └── venues/         # Customer venue details & facility media
└── shared/
    └── components/     # Reusable UI widgets (ErrorView, LocationPickerModal, etc.)
```

---

## 2. State Management Strategy (Riverpod)
PlayHub uses **Flutter Riverpod** with strict lifecycle management:

1. `FutureProvider.autoDispose`: Used for async API fetches (e.g. `nearbyVenuesProvider`, `adminWebhookLogsProvider`). Auto-disposes state when screens unmount to prevent memory leaks.
2. `StateNotifierProvider`: Used for stateful domain objects requiring methods (e.g. `userLocationProvider` managing `UserLocationNotifier`).
3. `StateProvider`: Used for simple filter state (e.g. `selectedCityProvider`, `searchStateProvider`).

---

## 3. Navigation & Route Protection (GoRouter)
- **Centralized Router**: `lib/app/router/router.dart` manages all routes.
- **Auth & Role Guard**: Automatically redirects unauthenticated users to `/login`.
- **Role Protection**:
  - `/admin-dashboard/*` requires `UserRole.admin`.
  - `/partner/*` requires `UserRole.businessOwner` or `UserRole.admin`.

---

## 4. Multi-Platform Parity Strategy (Android / iOS / Web)

PlayHub targets three supported platforms from a single Dart codebase:

```
                      [ Shared Core Domain ]
           (Models, Riverpod State, Dio API, GoRouter)
                               │
       ┌───────────────────────┼───────────────────────┐
       ▼                       ▼                       ▼
[ Android Execution ]    [ iOS Execution ]     [ Web PWA Execution ]
• Camera QR Scanner     • Camera QR Scanner   • Web QR Scanner
• Geolocator GPS        • CoreLocation GPS    • Browser Geolocation
• Push Notifications    • APNS Notifications  • Web Push
```

- **Platform Invariants**: 100% of business logic, models, API repositories, and Riverpod state are shared across all platforms.
- **Web Adaptation**: Responsive breakpoints adjust grid columns and navigation (Bottom Navigation Bar on mobile vs Navigation Rail on Desktop/Web).

---

## 5. Code Quality Audit Findings & Classifications

| Priority | Component | Issue / Risk | Resolution Strategy |
| :--- | :--- | :--- | :--- |
| **P0** | Router | Shadowed path conflicts | Resolved via named sub-routes in `router.dart` |
| **P1** | Network | Raw request timeout handling | Handled via Dio `ConnectTimeoutException` interceptor |
| **P2** | Location | GPS permission denial | Handled via city fallback in `LocationPickerModal` |
| **P3** | Theme | Hardcoded colors in old screens | Migrating to `Theme.of(context).colorScheme` tokens |
