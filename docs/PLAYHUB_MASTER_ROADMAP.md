# PlayHub Master Strategic Roadmap

## TIER 0 — CRITICAL DEFECTS & HARDENING
- None identified. Core booking and security layers are hardened.

## TIER 1 — REQUIRED FOR FIRST REAL LAUNCH (MVP+)
### Phase 43: Dynamic Discovery Foundation
**Objective**: Replace all remaining dummy discovery data.
- **Backend**: `Cities`, `Categories`, and `Activities` modules. ✅
- **Database**: Add `City` and `Activity` models and seed data. ✅
- **Flutter**: Update `HomeScreen` and `Discovery` flows to use real backend APIs. ✅
- **Priority**: High (Completed)

### Phase 44: Production Media Infrastructure
**Objective**: Display real venue images.
- **Strategy**: Implement AWS S3 or compatible object storage integration.
- **Scope**: Signed URLs for read access; Admin/Owner upload API.
- **Priority**: High

### Phase 45: Real Search & Filtering
**Objective**: Replace `Search Results` placeholder.
- **Implementation**: PostgreSQL full-text search. Filter by city, category, and date.
- **Priority**: High

## TIER 2 — HIGH-VALUE POST-LAUNCH
### Phase 46: External Communications
**Objective**: Move alerts outside the app.
- **Drivers**: SMTP (Email), SMS (Twilio/Msg91), Push (FCM).
- **Automation**: Reminders 2 hours before booking; Payment confirmation emails.

### Phase 47: Customer Trust Loop
**Objective**: Social proof for venues.
- **Scope**: Ratings and Reviews with booking-verified eligibility.

## TIER 3 — ARCHITECT NOW / ACTIVATE LATER
### Phase 48: Management Dashboards (V2)
**Objective**: Fully integrate Business and Admin dashboards.
- **Features**: Revenue tracking, member management, dispute resolution.

## TIER 4 — SCALE GROWTH
### Phase 49: Performance & Caching
**Objective**: Handle high concurrent slot requests.
- **Tech**: Redis caching for `AvailabilityService`.

## TIER 5 — MILLION-USER EVOLUTION
### Phase 50: Advanced Discovery & Infrastructure
**Objective**: Global scale readiness.
- **Tech**: Dedicated Search Engine (OpenSearch), Microservices for high-traffic modules.

---
**Next Recommended Action**: Proceed to Phase 43.
