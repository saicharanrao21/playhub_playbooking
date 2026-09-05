# PlayHub Official Design Language & System Tokens

## 1. Color System & Semantic Tokens

PlayHub uses FlexColorScheme with a custom sports-energy color palette:

| Token Name | Hex Code | Semantic Purpose |
| :--- | :--- | :--- |
| **Primary (Sport Green)** | `#10B981` | Core brand color, primary CTA buttons, open courts |
| **Primary Container** | `#D1FAE5` | Chip backgrounds, active selection highlights |
| **Secondary (Turf Teal)** | `#0D9488` | Headers, secondary buttons, venue categories |
| **Accent (Gold Prime)** | `#F59E0B` | Peak hour surcharges, ratings, warnings |
| **Error (Alert Red)** | `#EF4444` | Cancellations, failed payments, expired QR passes |
| **Surface Light** | `#F8FAFC` | App background in Light Mode |
| **Surface Dark** | `#0F172A` | App background in Dark Mode |
| **On-Surface Variant** | `#64748B` | Subtitles, secondary text, timestamps |

---

## 2. Typography Scale
Powered by `google_fonts` (Plus Jakarta Sans / Inter):

```
Headline Large:  28px / SemiBold (Screen Hero Titles)
Headline Medium: 22px / Bold     (Section Headers, Venue Titles)
Title Medium:    16px / SemiBold (Card Titles, Modal Headers)
Body Large:      14px / Regular  (Main Copy, Descriptions)
Body Medium:     12px / Medium   (Subtitle Text, Distance Badges)
Caption:         10px / Regular  (Timestamps, Helper Text)
```

---

## 3. Spacing & Radius Tokens

```
Spacing Scale:  [ 4, 8, 12, 16, 20, 24, 32, 48 ]
Radius Scale:   [ 8 (Chips/Badges), 12 (Buttons/Inputs), 16 (Cards/Modals), 24 (Sheets), 999 (Pills) ]
Elevation:      [ 0 (Flat), 1 (Standard Card), 3 (Hover/Focus), 6 (Modal Sheet) ]
```

---

## 4. Responsive Breakpoints

| Breakpoint Name | Width Threshold | Target Layout Behavior |
| :--- | :--- | :--- |
| **Mobile** | `< 600 px` | Single column, Bottom Navigation Bar, Full-screen Modals |
| **Tablet** | `600 - 900 px` | 2-column Grid, Navigation Rail, Side Sheets |
| **Desktop** | `900 - 1200 px` | 3-column Grid, Persistent Sidebar Navigation |
| **Large Desktop** | `> 1200 px` | 4-column Grid, Split List/Detail Admin Console |

---

## 5. Component Design Standards

### A. Court Slot Selector
- **Available Slot**: Light Green container (`#D1FAE5`) with dark green text (`#065F46`).
- **Booked Slot**: Light grey container (`#F1F5F9`) with disabled grey text (`#94A3B8`).
- **Peak/Prime Slot**: Light gold container (`#FEF3C7`) with gold border and badge ("Peak +₹200").

### B. Distance Badge
- Dark pill badge (`#1E293B`) with navigation icon and white bold text (`1.2 km`).

### C. Financial Status Chips
- `PROCESSED` / `APPROVED`: Green chip (`#DCFCE7` bg, `#15803D` text).
- `QUEUED` / `PROCESSING`: Orange chip (`#FFEDD5` bg, `#C2410C` text).
- `FAILED` / `REJECTED`: Red chip (`#FEE2E2` bg, `#B91C1C` text).

### D. QR Pass Component
- High-contrast white card on dark background with embedded QR image, venue address, booking reference ID, and animated countdown timer.
