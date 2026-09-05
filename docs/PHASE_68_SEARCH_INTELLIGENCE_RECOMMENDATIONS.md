# PlayHub Phase 68: Search Intelligence & Recommendation Engine

## 1. Executive Summary
Phase 68 implements a production-grade **Search Intelligence, Intent Parsing, Weighted Result Ranking, and Contextual Recommendation Engine** for PlayHub. The system normalizes raw search queries into structured domain intents (sports, price caps, time windows, indoor/outdoor preferences, and ranking intent), scores candidates using a deterministic 7-signal weighted scoring formula, generates contextual recommendation categories ("Recommended for You", "Available Court Slots Today", "Best Value Courts"), and provides cold-start fallbacks for new users.

## 2. Search Intelligence & Query Understanding Architecture
```
[ Raw Query e.g. "cricket turf under 600" ]
                    │
                    ▼
[ QueryUnderstandingService ]
 ├─► Detected Sports: ["cricket"]
 ├─► Max Price Cap: ₹600
 ├─► Time Intent: "TONIGHT"
 └─► Ranking Intent: "NEARBY"
                    │
                    ▼
[ Candidate Retrieval (VenuesService Bounding Box) ]
                    │
                    ▼
[ RankingScoringService (Weighted Formula) ]
 ├─► Text Relevance Score (25%)
 ├─► Activity Match Score (20%)
 ├─► Distance / Proximity Score (20%)
 ├─► Bookable Availability Score (15%)
 ├─► Rating & Quality Score (10%)
 ├─► Price Competitiveness Score (5%)
 └─► Personalization History Score (5%)
                    │
                    ▼
[ Diversity Filter ] ──► [ Search & Recommendation Response ]
```

## 3. Contextual Recommendation Engine
- **`RecommendationService`** (`GET /api/v1/recommendations`):
  - **Authenticated Users**: Analyzes `Booking` history in PostgreSQL to identify favorite sports and preferred venues. Generates personalized `RECOMMENDED_FOR_YOU` and `BASED_ON_RECENT_BOOKINGS` sections.
  - **Cold-Start Fallback**: For new users or guest discovery, falls back to `location + activity + popularity + rating` to present top-rated active venues with open slots nearby.
  - **`AVAILABLE_NOW`**: Highlights venues with open bookable court slots today.
  - **`BEST_VALUE`**: Ranks courts with competitive pricing and active promo discounts.

## 4. Search Autocomplete & Suggestions
- **`SuggestionsService`** (`GET /api/v1/search/suggestions?q=...`):
  - Provides fast autocomplete suggestions for sports, venue names, and popular nearby categories.

## 5. Admin Ranking Configuration
- `GET /api/v1/admin/search/config` and `POST /api/v1/admin/search/config`:
  - Enables platform operators to inspect and fine-tune scoring weights (`textRelevance`, `activityMatch`, `locationDistance`, `availability`, `ratingQuality`, `priceCompetitiveness`, `personalization`).
  - Guarded by `PlatformAdminGuard`.

## 6. Customer Flutter UX
- **`HomeScreen`**: Renders horizontal recommendation carousels for "Recommended for You", "Available Court Slots Today", and "Best Value Courts".
- **`SearchScreen`**: Enhanced with relevance badges on candidate cards ("Under 2 km", "Top CRICKET Turf", "★ 4.8 High Quality").

## 7. Verification & Test Results
- **Backend Unit Tests**: 31/31 Test Suites Passed (110 total tests passed, including `QueryUnderstandingService`, `RankingScoringService`, and `SuggestionsService` test cases).
- **Prisma Schema & Validation**: Valid (`npx prisma validate`).
- **NestJS Build**: Succeeded (`nest build`).
- **Flutter Analyze**: 0 issues found (`flutter analyze` clean).
- **Flutter Tests**: Passed.
- **Flutter Web Build**: Succeeded (`flutter build web --release`).
- **Regression Check**: Customer V3, Partner Workspace, Admin Operations Console, Geolocation, Redis, BullMQ, Observability, Object Storage, Webhooks, Memberships/Coupons/Loyalty, and WebSockets/Match Chat remain 100% operational.
