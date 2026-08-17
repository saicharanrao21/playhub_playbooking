# Current State Snapshot - PlayHub Prototype

Date: 2026-08-17

## Project Overview
The project is a Flutter application intended for venue booking, currently in a prototype/legacy state. It features a basic UI for customers, business owners, and admins.

## Project Structure
- **Root:** `D:/Flutter/playhub_playbooking`
- **Flutter Version:** Environment SDK `^3.12.1`
- **Architecture:** Feature-based modular structure (`lib/features/`) with a `core/` layer for shared logic.
- **State Management:** `flutter_riverpod`
- **Navigation:** `go_router`
- **Theming:** `flex_color_scheme`
- **Responsiveness:** `responsive_framework`

## Directory Breakdown
- `lib/core/`: Models, dummy repositories, providers, and theme.
- `lib/features/`: 
  - `admin_dashboard`: Basic admin screen.
  - `auth`: Simple login screen.
  - `business_dashboard`: Basic business owner screen.
  - `home`: Main landing screen for customers.
  - `profile`: User profile screen.
  - `venues`: Venue list and details.
- `lib/routes/`: Centralized routing configuration.

## Dependencies
- `cupertino_icons: ^1.0.8`
- `flex_color_scheme: ^8.0.0`
- `flutter_riverpod: ^2.5.1`
- `go_router: ^14.2.2`
- `google_fonts: ^6.0.0`
- `responsive_framework: ^1.2.0`

## Implementation Details
- **Authentication:** Mocked in `DummyAuthRepository`. Hardcoded "login" always succeeds and returns a customer role.
- **Data:** Dummy data stored in `DummyData` class within `dummy_repositories.dart`.
- **Navigation:** Uses `go_router` with placeholder screens for unimplemented features (Search, Booking Confirmation).
- **Security:** 
  - [SECURITY RISK] Mock authentication with no real token handling.
  - [SECURITY RISK] Client-side role checking (if any) is easily bypassed.
  - [SECURITY RISK] No backend validation of operations.

## Technical Debt / Known Limitations
- Entirely client-side prototype.
- No real backend or database integration.
- UI components are tightly coupled with dummy repositories.
- Lacks unit and integration tests (only default `widget_test.dart` exists).

## Prototype Assessment

### KEEP / REUSE
- Feature-based directory structure (conceptually).
- `go_router` setup for navigation.
- `flex_color_scheme` for theming.
- UI layouts and responsive breakpoints (as a baseline).

### REFACTOR
- Separation of concerns between UI and business logic (needs more formal Clean Architecture).
- Provider definitions (should be moved to feature-specific folders where appropriate).

### REPLACE
- `DummyAuthRepository` and `DummyVenueRepository` with real implementations.
- Dummy models with more robust data structures.
- Navigation logic to include deep linking and better guardrails.

### REMOVE LATER
- `PlaceholderScreen` class.
- Hardcoded string constants in UI files (should use localization).

### SECURITY RISK
- Mock authentication logic.
- Hardcoded API endpoints or keys (if any found during deep dive).
- Lack of proper error handling for network/database failures.
