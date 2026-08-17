# Backend Architecture

## Overview
The PlayHub backend is a modular monolith designed for scalability, security, and multi-tenant isolation. It serves as the authoritative source for all business logic and security decisions.

## Technology Stack
- **NestJS:** Enterprise-grade Node.js framework for building efficient, reliable and scalable server-side applications.
- **PostgreSQL:** Primary relational database for transactional integrity.
- **Prisma:** Modern ORM for type-safe database access and migrations.
- **JWT:** Stateless authentication using short-lived access tokens and rotating refresh tokens.

## Module Boundaries
- **AuthModule:** Manages identity verification, token issuance, and session lifecycle.
- **UsersModule:** Handles user profile data and account status.
- **OrganizationsModule:** Core multi-tenancy logic, memberships, and roles.
- **PrismaModule:** Global database connection management.

## Authentication Model
The backend implements a secure token rotation strategy:
1. **Login:** Returns an `accessToken` (15m) and `refreshToken` (7d).
2. **Access Token:** Included in the `Authorization: Bearer` header for every request.
3. **Refresh Token:** Used once to obtain a new token pair. Previous refresh tokens are invalidated upon use to prevent replay attacks.
4. **Sessions:** Tracks active devices/logins.

## Authorization Model
Roles and Permissions are managed via a flexible RBAC (Role-Based Access Control) system:
- **Permissions:** Granular `action:resource` pairs (e.g., `create:booking`, `read:venue`).
- **Roles:** Collections of permissions (e.g., `VenueManager` has all venue-related permissions).
- **Membership:** Links a User to an Organization with specific Roles.

## Tenant Isolation
Tenant isolation is enforced at the service layer:
- Every request context should include an `organizationId`.
- Database queries must filter by `organizationId` for all scoped resources.
- Middleware/Guards verify that the user has a valid membership in the requested organization.

## Error Model
The API returns a consistent error format:
```json
{
  "statusCode": 400,
  "message": "Validation failed",
  "error": "Bad Request",
  "code": "VALIDATION_ERROR",
  "timestamp": "2026-08-17T12:00:00Z",
  "path": "/api/v1/auth/login"
}
```
Stack traces are suppressed in production.
