# API Documentation Guide

PlayHub APIs are fully documented using **Swagger/OpenAPI**.

## 🚀 Accessing the Documentation

When running the backend in development mode, the interactive Swagger UI is available at:
`http://localhost:3000/docs`

---

## 🔑 Authentication

Most endpoints require a valid JWT Access Token.
- **Header**: `Authorization: Bearer <access_token>`
- **Refresh**: Use `/auth/refresh` with the HTTP-only (or body) refresh token to obtain a new access token.

---

## 🏢 Multi-Tenancy

Every organization-scoped request must include the organization ID.
- **Header**: `x-organization-id: <org_uuid>`
- **URL Context**: Routes typically follow the pattern `/organizations/:organizationId/...`.

The `OrganizationGuard` verifies that the authenticated user has a valid membership in the requested organization.

---

## 🛡️ Idempotency

Mutative operations (like creating a booking or initiating a payment) support idempotency to prevent duplicate records during network retries.
- **Header**: `x-idempotency-key: <unique_string>`

---

## 📡 Webhooks

Webhook endpoints for Razorpay and Stripe are located at:
`POST /organizations/:orgId/payments/webhook/:provider`

**Security Notice**: 
- Webhook endpoints are public but **mandatory signature verification** is performed using the configured provider secrets.
- Replay protection is handled via provider-specific event IDs.
