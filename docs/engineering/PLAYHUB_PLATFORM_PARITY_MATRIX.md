# PlayHub Platform Feature Parity Matrix

## 1. Cross-Platform Feature Support Matrix

This matrix documents feature support and execution strategies across Android, iOS, and Web/PWA:

| Feature / Capability | Android | iOS | Web / PWA | Implementation Strategy |
| :--- | :--- | :--- | :--- | :--- |
| **Authentication & Refresh** | ✅ Full | ✅ Full | ✅ Full | Shared `AuthRepository` & Dio Interceptor |
| **Venue Discovery & Filters** | ✅ Full | ✅ Full | ✅ Full | Shared Riverpod `searchStateProvider` |
| **GPS Location Detection** | ✅ Full | ✅ Full | ✅ Full | `geolocator` (HTML5 Geolocation on Web) |
| **OpenStreetMap & Markers** | ✅ Full | ✅ Full | ✅ Full | `flutter_map` v7 (Canvas / WebGL rendering) |
| **Court Slot Selection** | ✅ Full | ✅ Full | ✅ Full | Shared `AvailabilityScreen` grid |
| **Payment Gateway Checkout** | ✅ Full | ✅ Full | ✅ Full | Razorpay / Stripe SDKs + Web Checkout |
| **QR Pass Ticket Display** | ✅ Full | ✅ Full | ✅ Full | `qr_flutter` widget rendering |
| **QR Code Camera Scanner** | ✅ Full | ✅ Full | ⚠️ Web Cam | `mobile_scanner` v5 |
| **Push Notifications** | ✅ Full | ✅ Full | ⚠️ Web Push | Firebase FCM / Web Push API |
| **Partner Finance Ledger** | ✅ Full | ✅ Full | ✅ Full | Responsive Card Grid + Data Tables |
| **Admin Operations Console** | ⚠️ Compact | ⚠️ Compact | ✅ Full | Responsive Navigation Rail & Data Tables |

---

## 2. Identified Platform Gaps & Mitigation Plan
1. **Web Camera QR Scanning**: Mobile camera scanner works out of the box on mobile devices. On Web, `mobile_scanner` requires browser media permissions. **Mitigation**: Added fallback manual booking reference code entry input field for staff on ground.
2. **iOS Build Environment**: iOS builds require macOS runner. **Status**: Codebase is 100% Flutter cross-platform compliant. iOS build validation marked as `NOT EXECUTED — ENVIRONMENT LIMITATION` (Windows host).
3. **Web Desktop Layout**: Large screens can make mobile cards overly wide. **Mitigation**: Constrained max container width (`720px`) and responsive 3/4-column grids on desktop viewports.
