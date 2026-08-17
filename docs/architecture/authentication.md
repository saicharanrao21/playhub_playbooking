# Authentication Architecture

## Overview
PlayHub uses a token-based authentication system (JWT) designed for secure identity management and future backend integration.

## State Machine
The authentication lifecycle is managed by `AuthState` with the following statuses:
- `initializing`: App is restoring session from secure storage.
- `unauthenticated`: No valid session exists.
- `authenticating`: Login request is in progress.
- `authenticated`: User has a valid session and identity.
- `refreshing`: Access token is being renewed using a refresh token.
- `sessionExpired`: Session is no longer valid and requires re-authentication.
- `error`: An authentication error occurred.

## Secure Storage
Tokens are stored in platform-specific secure storage (Android Keystore / iOS Keychain) via the `TokenStorage` abstraction.
- **Access Token:** Short-lived token for authorizing API requests.
- **Refresh Token:** Long-lived token for obtaining new access tokens.

## API Client Integration
The ` DioApiClient` automatically attaches the `Authorization: Bearer <token>` header to requests marked as `authenticated: true`. It handles 401 errors by triggering the session refresh flow.

## Auth Guards (GoRouter)
Routing is reactive to `authStateProvider`. 
- Unauthenticated users are redirected to `/login`.
- Authenticated users attempting to access `/login` are redirected to `/`.

## Domain Model
- `UserIdentity`: Represents the authenticated user's profile and role.
- `AuthSession`: Represents the active session including tokens and expiry.

## Security Controls
- **Redaction:** `AppLogger` redacts tokens and passwords from console logs.
- **No Plaintext:** Tokens are never stored in `SharedPreferences` or plain files.
- **Centralized Logic:** UI never touches tokens; all logic is encapsulated in `AuthRepository` and `AuthNotifier`.
