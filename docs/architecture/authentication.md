# Authentication Architecture (v2)

## Overview
PlayHub implements a secure, token-based authentication system using NestJS and Flutter. The server is the absolute authority for identity and session management.

## State Machine
The authentication lifecycle is managed by `AuthState` in Flutter and `AuthService` in NestJS:
- `initializing`: App is restoring session from secure storage.
- `unauthenticated`: No valid session exists.
- `authenticating`: Login/Registration request is in progress.
- `authenticated`: User has a valid session and identity.
- `refreshing`: Access token is being renewed using a refresh token.
- `sessionExpired`: Session is no longer valid and requires re-authentication.

## Token Lifecycle & Security
1. **Access Token:** Short-lived (15m) JWT. Used for authorizing API requests.
2. **Refresh Token:** Long-lived (7d) rotating token.
3. **Rotation:** Every time a refresh token is used, a new pair is issued. The old refresh token is invalidated.
4. **Reuse Detection:** If a refresh token is reused, the entire session is revoked and flagged as potential fraud.
5. **Secure Storage:** Tokens are stored in Keychain (iOS) and Keystore (Android).

## API Hardening
- **Global Exception Filter:** Standardizes all error responses and prevents internal data leakage.
- **Request ID:** Every request is assigned a unique ID for end-to-end tracing.
- **Audit Logging:** Security-sensitive mutations are automatically logged to the `audit_logs` database table.
- **Rate Limiting:** (Planned) Brute-force protection for auth endpoints.

## Auth Flow (E2E)
1. **Registration:** `POST /auth/register` -> Bcrypt hashing -> Create User -> Issue Tokens.
2. **Login:** `POST /auth/login` -> Verify Hash -> Create Session -> Issue Tokens.
3. **Request:** Client adds `Authorization: Bearer <access>` header.
4. **Refresh:** If 401 received, `AuthInterceptor` calls `POST /auth/refresh` -> Validate sid -> Rotate Tokens -> Retry Request.
5. **Logout:** `POST /auth/logout` -> Revoke Session in DB -> Clear local storage.

## Password Security
- Never stored in plaintext.
- Never logged.
- Minimum length enforced (8 chars).
- Hashed with `bcrypt` (cost factor 10).
