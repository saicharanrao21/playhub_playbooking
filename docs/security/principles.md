# Security Principles

## 1. Zero Trust Client
The mobile/web client is considered untrusted. All sensitive operations must be verified and authorized by the server.

## 2. Secure Local Storage
- **Sensitive Data:** Access tokens, refresh tokens, and session secrets must be stored in `SecureStorage` (Keychain/Keystore).
- **Non-Sensitive Data:** Theme preferences, UI settings, and cache can be stored in `LocalStorage` (Shared Preferences).

## 3. Data Redaction
The logging system is designed to automatically redact common sensitive keys. Developers must use `logSensitive` when dealing with data that might contain credentials.

## 4. No Hardcoded Secrets
- API keys and environment secrets must not be committed to the repository.
- Use `dart-define` or environment variables to inject values during build.

## 5. Token Management
Tokens should be handled through an automated mechanism in the `IApiClient` (Interceptors) to avoid manual leakage in feature code.
