# Security Architecture & Authority

## Authority Principle
The server is the ONLY authority for:
- Identity verification (Authentication).
- Permission enforcement (Authorization).
- Resource ownership (Multi-tenancy).
- Business rule validation (e.g., booking slots, pricing).

## Data Protection
1. **Passwords:** Never stored in plaintext. Hashed using `bcrypt` with a minimum cost factor of 10.
2. **Tokens:** 
   - `JWT` access tokens are stateless and short-lived.
   - `Refresh Tokens` are stored as hashes in the database and rotated upon use.
3. **Transport:** All API communication MUST be over HTTPS (enforced in production).
4. **Headers:** `Helmet` middleware is used to set secure HTTP headers (XSS protection, Clickjacking prevention, etc.).

## Authentication Flow
1. Client sends credentials to `/auth/login`.
2. Server validates credentials against the database.
3. Server creates a `Session` and issues a `Token Pair`.
4. Client stores tokens in `SecureStorage`.
5. Server verifies JWT on every protected request via `JwtStrategy`.

## Input Validation
- All request bodies are validated against DTOs using `class-validator`.
- Unexpected properties are stripped (Whitelist mode).
- Strong typing is enforced for all inputs.

## Logging & Auditing
- Sensitive data (passwords, tokens) is NEVER logged.
- Critical operations (login, membership changes, deletions) are recorded in the `audit_logs` table.
- Every request is assigned a `Correlation ID` for end-to-end tracing.
