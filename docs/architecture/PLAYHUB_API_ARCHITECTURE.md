# PlayHub API Architecture & Integration Contracts

## 1. API Conventions & Headers
All PlayHub backend endpoints conform to RESTful standards:

- **Base URL**: `https://api.playhub.app/api/v1`
- **Content-Type**: `application/json`
- **Standard Request Headers**:
  - `Authorization`: `Bearer <jwt_access_token>`
  - `x-organization-id`: `<organization_uuid>` (Mandatory for partner organization routes)
  - `x-idempotency-key`: `<unique_client_uuid>` (Optional client deduplication header)
  - `x-request-id`: `<trace_uuid>` (Injected by `RequestIdMiddleware`)

---

## 2. Standardized Response & Error Contracts

### Successful Response:
```json
{
  "statusCode": 200,
  "data": {
    "items": [...],
    "total": 42
  },
  "timestamp": "2026-09-05T10:00:00.000Z",
  "requestId": "req_8f91a2b3"
}
```

### Standard Error Response:
```json
{
  "statusCode": 400,
  "error": "Bad Request",
  "message": ["amount must be a positive number"],
  "timestamp": "2026-09-05T10:00:00.000Z",
  "requestId": "req_8f91a2b3"
}
```

---

## 3. Endpoint Catalog Summary

### A. Customer Discovery & Search
- `GET /api/v1/discovery/venues/nearby?latitude=17.44&longitude=78.34&radius=10&query=cricket&sortBy=distance`
- `GET /api/v1/discovery/geocode/reverse?latitude=17.44&longitude=78.34`

### B. Bookings & Availability
- `GET /api/v1/facilities/:facilityId/availability?date=2026-09-06`
- `POST /api/v1/bookings` (Creates booking & holds slot)

### C. Payment Webhooks
- `POST /api/v1/webhooks/razorpay` (Verifies `x-razorpay-signature`, enqueues to BullMQ)
- `POST /api/v1/webhooks/stripe` (Verifies `stripe-signature`, enqueues to BullMQ)

### D. Partner Workspace
- `GET /api/v1/organizations/:orgId/finance/summary`
- `POST /api/v1/organizations/:orgId/finance/payouts/request`

### E. Admin Operations Console
- `GET /api/v1/admin/webhooks`
- `POST /api/v1/admin/webhooks/:id/retry`
- `GET /api/v1/admin/finance/reconciliation`
- `GET /api/v1/admin/queues/health`
