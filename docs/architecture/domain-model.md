# PlayHub Domain Model

## Core Entity Hierarchy

The PlayHub business domain is structured as a strictly isolated multi-tenant hierarchy:

```text
Organization (Tenant)
   ↓
Business (Legal Operator)
   ↓
Venue (Physical Location)
   ↓
Facility (Bookable Resource)
```

### 1. Organization
The top-level commercial tenant. All data is scoped to an organization.
- **Status:** ACTIVE, SUSPENDED, ARCHIVED.
- **Isolation:** Enforced via `OrganizationGuard` and service-layer ownership checks.

### 2. Business
Represents the legal entity or operator managing venues.
- **Relationship:** Belongs to exactly one Organization.
- **Fields:** Legal name, display name, status.

### 3. Venue
A physical sports arena, gym, or stadium.
- **Relationship:** Belongs to a Business.
- **Location:** Normalized fields for Address, City, State, Country, Postal Code, and Coordinates (Lat/Long).
- **Status:** DRAFT, PENDING_APPROVAL, ACTIVE, SUSPENDED.
- **Uniqueness:** Slug is unique within the scope of a Business.

### 4. Facility
The actual bookable resource (e.g., Football Turf, Badminton Court 1).
- **Relationship:** Belongs to a Venue.
- **Category:** Dynamic categories (Badminton, Cricket, etc.) defined in the `Category` model.
- **Properties:** Capacity, display order, status.

## Foundational Domains

### Operating Hours
Structured opening and closing times per day of the week for each Venue.
- Supports `isClosed` flag for holidays/maintenance.

### Availability Foundation
The `AvailabilityBlock` model tracks temporary closures, maintenance, and blackout periods.
- Prevents booking during these intervals.

### Pricing Foundation
The `PricingRule` model establishes a base price and currency per Facility.
- Designed for future expansion into dynamic/peak pricing.

## Security & Isolation
- **Ownership Verification:** Every mutation (Create, Update, Delete) verifies that the target resource belongs to the authorized `organizationId` from the JWT context.
- **IDOR Protection:** Database queries use composite filters (e.g., `where: { id: facilityId, venue: { business: { organizationId } } }`).
- **Auditability:** All domain mutations are captured by the `AuditInterceptor`.

## Operator Flow (E2E)
1. **User Login:** Authenticated session associated with one or more Organizations.
2. **Context Selection:** Client selects an Organization and sets `x-organization-id` header.
3. **Business Management:** CRUD operations on Businesses within the organization.
4. **Venue Management:** Creation of Venues, definition of location and timezone.
5. **Operational Setup:** 
   - Define Operating Hours in venue-local time.
   - Configure Facilities (Courts/Turfs).
   - Manage Availability Blocks (Maintenance/Holidays).
