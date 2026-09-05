# PlayHub Master UX/UI Brief

## 1. Design Statement & Brand Personality
PlayHub's brand identity is defined by a single core statement:

> **"Sport energy with marketplace precision."**

PlayHub avoids generic SaaS corporate visual tropes and hyper-abstract AI designs. Instead, it balances the raw, vibrant energy of live sports with the crisp, trustworthy precision of an enterprise transaction engine.

```
       VIBRANT SPORT ENERGY                    MARKETPLACE PRECISION
┌──────────────────────────────────┐    ┌──────────────────────────────────┐
│ • High-contrast athletic accents │    │ • Clean grid alignment           │
│ • Dynamic court availability     │ +  │ • Precise monetary formatting    │
│ • Single-tap action buttons      │    │ • Clear double-entry status      │
│ • Immersive venue photography    │    │ • Instant QR scan feedback       │
└──────────────────────────────────┘    └──────────────────────────────────┘
```

---

## 2. Product Surface UX Strategies

### Surface 1: Customer App (Energetic & Frictionless)
- **Goal**: Help sports players find a court within 30 seconds and complete booking in under 3 taps.
- **Key UX Patterns**:
  - Top AppBar location badge showing current GPS area and search radius.
  - Interactive OpenStreetMap view with custom sport markers.
  - Distance badges ("1.2 km away") on venue cards.
  - Interactive court slot picker with color-coded availability (Green = Open, Grey = Booked, Gold = Prime Time).

### Surface 2: Partner / Owner App (Operational & Actionable)
- **Goal**: Provide venue managers with an efficient, high-contrast operational terminal.
- **Key UX Patterns**:
  - High-visibility QR code scanner camera viewport.
  - One-tap booking Accept/Reject action buttons.
  - Clear financial cards showing Gross Earnings, Commission, and Net Available Payable Balance.
  - Masked bank account display for payout destinations.

### Surface 3: Admin Operations Console (Dense & Auditable)
- **Goal**: Enable internal operators to manage 10,000+ venues and millions of transactions with maximum data density and audit transparency.
- **Key UX Patterns**:
  - Compact data tables with status chips (`PROCESSED`, `FAILED`, `APPROVED`).
  - Searchable audit trails with user actor and timestamp logs.
  - Financial discrepancy alerts with immediate "Run Reconciliation" triggers.
