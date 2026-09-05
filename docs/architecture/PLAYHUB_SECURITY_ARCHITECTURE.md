# PlayHub Security Architecture

## 1. Authentication & Session Security
- **JWT Architecture**: Dual-token model with short-lived Access Tokens (15m TTL) and hashed Refresh Tokens (7d TTL) stored in `refresh_tokens` table.
- **Password Protection**: Passwords hashed with `bcrypt` (10 rounds). Plaintext passwords never stored.

---

## 2. Role-Based Access Control (RBAC) & Tenant Isolation
PlayHub enforces a 3-tier guard hierarchy:

```
[ Incoming Request ]
        │
        ▼
[ JwtAuthGuard ] ──► (Verify Bearer Token & User Identity)
        │
        ▼
[ OrganizationGuard ] ──► (Verify User Membership in x-organization-id)
        │
        ▼
[ PermissionsGuard ] ──► (Verify Role Permissions for action/resource)
```

- **IDOR Protection**: `OrganizationGuard` verifies that the requesting user belongs to the target `organizationId`. A partner user cannot query or mutate another partner's venues, bookings, or financial records.

---

## 3. Webhook Security
- **Server-Side Signature Validation**:
  - Razorpay: HMAC-SHA256 of `rawBody` using `RAZORPAY_WEBHOOK_SECRET`.
  - Stripe: Verified using `stripe.webhooks.constructEvent` with `STRIPE_WEBHOOK_SECRET`.
- **Invalid Signatures**: Requests with invalid signatures are rejected immediately with HTTP 400 Bad Request and logged to audit trail.

---

## 4. Sensitive Data Masking & PII Protection
- Bank account numbers are masked in all API responses (`XXXXXX1234`).
- Sensitive payment secrets (webhook secrets, API keys, JWT secrets) are kept strictly in server-side environment variables and never exposed to Flutter clients.

---

## 5. Audit Logging
Every privileged action (KYC approval, financial adjustment, payout request, webhook retry) writes an entry to `audit_logs` containing `userId`, `organizationId`, `action`, `resourceId`, and `ipAddress`.
