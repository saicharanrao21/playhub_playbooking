# PlayHub Phase 61: Location-Aware Discovery & Search Intelligence

## 1. Executive Summary
Phase 61 builds on top of Phase 60's geolocation & map foundation to deliver a fully integrated, production-grade **Location-Aware Discovery & Search Intelligence System** for PlayHub. Customers can seamlessly search for sports venues, filter by configurable search radii (2-50 km), sort by distance, rating, or price, and toggle between synchronized list and map views without losing the PlayHub V3 visual identity.

## 2. Customer Discovery Architecture & State Flow
- **`SearchQuery` Model**: Encapsulates text query, city, category, activity, latitude, longitude, search radius (km), and sort criteria (`distance`, `price`, `rating`).
- **Debounced Text Search**: Text inputs in `SearchScreen` update state with a 300ms debounce timer to prevent excessive API requests during typing.
- **Server-Authoritative Proximity**: All proximity calculations, bounding-box candidate selections, and distance sortings are executed server-side in NestJS + PostgreSQL.

## 3. Discovery UX & Map Synchronization
- **`HomeScreen` Integration**: Header bar displays active location name and search radius. Displays nearby venues with distance badges ("1.2 km away") and map preview shortcut.
- **`SearchScreen` Filters**: Scrollable filter bar with modal trigger, search radius choices (2 km, 5 km, 10 km, 25 km, 50 km), sort options (Nearest, Top Rated, Lowest Price), and sports category chips.
- **`MapViewScreen` Synchronization**: Renders user GPS position and venue markers using OpenStreetMap tiles (`flutter_map`). Selecting a marker highlights the venue and opens an interactive card leading into `VenueDetailsScreen`.

## 4. Location Permission & Fallback Behavior
- **GPS Available**: Uses live coordinates for nearby venue discovery.
- **GPS Denied/Unavailable**: Gracefully falls back to city-based discovery without breaking or crashing the application.
- **Manual Location Override**: Customers can manually select an operating city or set search coordinates via `LocationPickerModal`.

## 5. Security & Performance
- **1M+ Scale Bounding-Box Query**: PostgreSQL index query on `venues(status, latitude, longitude)` bounds candidate results before exact Haversine distance sorting.
- **Tenant & API Safety**: Server-side DTO validation enforces radius limits (0.5 to 100 km) and pagination limits.

## 6. Testing & Regression Validation
- **Backend Tests**: 80/80 tests passed across 22 test suites.
- **Flutter Analyze**: 0 issues found (`flutter analyze` clean).
- **Flutter Tests**: Passed.
- **Regression Check**: Customer V3 booking journey, Partner venue management, and Admin Operations Console remain 100% operational.
