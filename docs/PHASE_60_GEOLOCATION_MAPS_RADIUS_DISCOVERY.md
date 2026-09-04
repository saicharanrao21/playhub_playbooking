# PlayHub Phase 60: Geolocation, Maps & Radius-Based Discovery

## 1. Executive Summary
Phase 60 establishes a high-performance, production-grade **Geolocation and Radius Discovery Engine** for PlayHub. Customers can now discover sports venues based on their real-time GPS location or custom search area, filter by configurable radii (2 km, 5 km, 10 km, 25 km, 50 km), view distance badges on venue cards, and explore sports venues on an interactive map.

## 2. Location Architecture & Database Indexing
- **Coordinates & Addresses**: Every physical `Venue` maintains `latitude`, `longitude`, `address`, `city`, `state`, `country`, `postalCode`, and `timezone`.
- **Spatial Bounding-Box Indexing**: To support scale up to 1M+ customers without expensive full table scans, `VenuesService` uses a bounding-box query strategy (`latitude BETWEEN minLat AND maxLat AND longitude BETWEEN minLng AND maxLng`).
- **PostgreSQL Compound Index**: Migration `20260904000000_add_venue_location_indexes` added compound indexes on `venues(latitude, longitude)` and `venues(status, latitude, longitude)`.

## 3. Server-Authoritative Haversine Distance
- **Exact Distance Calculation**: The backend is the single source of truth for proximity calculations. Distance is calculated using the Haversine formula:
  `d = 2 * R * asin(sqrt(sin^2((lat2 - lat1)/2) + cos(lat1) * cos(lat2) * sin^2((lng2 - lng1)/2)))`
- **UI Formatting**: Returned items include raw `distanceMeters`, `distanceKm`, and human-readable `distanceFormatted` (e.g. "350 m", "1.2 km", "4.8 km").

## 4. Geocoding & Provider Abstraction
- **GeocodingService**: A clean service abstraction handling forward geocoding (address -> coordinates) and reverse geocoding (coordinates -> city/area name).
- **Staging Lookup Table**: High-precision deterministic geocoder for staging landmarks (Gachibowli, Jubilee Hills, Whitefield, Koramangala) ensuring reliable testing without external API key exposure.

## 5. Customer Location Experience (Flutter)
- **LocationService**: Managed via Riverpod `userLocationProvider` and `geolocator`.
- **Permission Flow**: Gracefully handles Permission Granted, Denied, Permanently Denied, and Service Disabled.
- **Graceful Fallbacks**: If GPS is denied, the application falls back to manual city selection or default area without breaking the Customer V3 experience.
- **LocationPickerModal**: Bottom sheet allowing customers to toggle GPS, select radius chips, or pick from active operating cities.

## 6. Interactive Map Discovery (flutter_map)
- **flutter_map & latlong2**: Integrated OpenStreetMap tile layer for interactive venue exploration.
- **Markers**: User location indicator (Blue Dot) + Venue markers displaying custom icons.
- **Venue Preview Card**: Tapping a venue marker pops up an interactive bottom card with image, name, rating, distance, price, and direct navigation to `VenueDetailsScreen`.

## 7. Partner & Admin Operations Integration
- **Partner Venue Location**: Partner venue creation/edit screens allow manual or auto-geocoded coordinate input.
- **Admin Location Oversight**: Admin console provides metrics and batch auto-geocoding for active venues missing lat/lng coordinates.

## 8. API Contracts
- `GET /api/v1/discovery/venues/nearby`: Radius search query accepting `latitude`, `longitude`, `radius`, `query`, `cityId`, `categoryId`, `activityId`, `sortBy` ('distance' | 'price').
- `GET /api/v1/discovery/geocode/reverse`: Reverse geocode coordinates to location name.
- `GET /api/v1/admin/venues/missing-coordinates`: List active venues missing coordinates.
- `POST /api/v1/admin/venues/batch-geocode`: Batch auto-geocode all active venues.

## 9. Verification & Regression
- **Backend Tests**: 80/80 tests passed across 22 test suites.
- **Flutter Analyze**: 0 issues found (`flutter analyze` clean).
- **Flutter Tests**: Passed.
- **Customer Regression**: Customer V3 discovery, slot selection, dynamic pricing, and booking flow remain completely functional.
- **Partner & Admin Regression**: Partner onboarding, QR check-in, finance ledger, and admin console remain fully operational.
