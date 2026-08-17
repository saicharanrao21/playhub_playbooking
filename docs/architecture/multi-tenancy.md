# Multi-Tenancy Foundation

## Goal
To support multiple independent businesses (Organizations) on a single platform with absolute data isolation.

## Entities
- **Organization:** The top-level tenant (e.g., "Skyline Sports Center").
- **User:** A global identity that can belong to multiple organizations.
- **Membership:** The join entity that defines a user's relationship with an organization.

## Isolation Strategy
1. **Database Level:** Shared database with `organization_id` on all tenant-owned tables.
2. **API Level:** 
   - Public resources (e.g., browsing venues) are globally accessible.
   - Private resources require an `X-Organization-Id` header or path parameter.
3. **Application Level:** 
   - A `TenantInterceptor` extracts the organization context.
   - Services use a `TenantContext` to ensure all queries are scoped.

## Resource Hierarchy
```text
Platform
├── Organization (Tenant)
│   ├── Venue
│   │   ├── Court/Field
│   │   └── Slot
│   ├── Booking
│   ├── Staff
│   └── Payout Account
└── Global User (Identity)
```

## Security Principles
- A user must have an active `Membership` to access an `Organization`.
- The `Membership` must have a `Role` with the required `Permission`.
- Organization cross-talk is impossible as all queries are automatically scoped by the backend.
