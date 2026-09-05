# PlayHub Application Flows & Journey Architecture

## 1. Customer End-to-End Discovery & Booking Flow

```
[ Customer Launch ]
        │
        ▼
[ Location Permission Modal ] ──(Denied)──► [ Fallback: Select City / Manual Search ]
        │ (Granted GPS)
        ▼
[ HomeScreen: GPS Coordinates + Radius ]
        │
        ├─► [ Map View Screen ] ──(Tap Marker)──► [ Venue Preview Bottom Card ]
        │                                                     │
        └─► [ Search Bar / Filter Modal ]                     │
                     │                                        │
                     ▼                                        ▼
        [ Nearby Venues List ] ───────────────► [ VenueDetailsScreen ]
                                                      │
                                                      ▼
                                           [ Select Court/Facility ]
                                                      │
                                                      ▼
                                           [ Availability Calendar ]
                                                      │
                                                      ▼
                                           [ Dynamic Pricing Slot ]
                                                      │
                                                      ▼
                                           [ Booking Review Screen ]
                                                      │
                                                      ▼
                                            [ Payment Gateway ]
                                                      │ (Razorpay / Stripe)
                                                      ▼
                                           [ Webhook / Event Stream ]
                                                      │
                                                      ▼
                                           [ Booking Confirmed Pass ]
                                                      │
                                                      ▼
                                           [ QR Ticket Check-In ]
```

---

## 2. Partner Onboarding & Operations Flow

```
[ Partner Sign Up ] ──► [ Create Organization ] ──► [ KYC Document Submission ]
                                                              │ (PAN, GST, Bank Info)
                                                              ▼
                                                   [ State: SUBMITTED ]
                                                              │
                                            (Admin Review) ───┤
                                                              ▼
                                                   [ State: APPROVED ]
                                                              │
                                                              ▼
                                                    [ Business Activated ]
                                                              │
        ┌─────────────────────────────────────────────────────┼─────────────────────────────────────────────────────┐
        ▼                                                     ▼                                                     ▼
[ Add Venue & Courts ]                             [ Operating Hours & Pricing ]                         [ QR Check-In Scanner ]
(Geocodes Lat/Lng)                                 (Peak Hour Rules / Blocks)                            (Staff App Scan Ticket)
        │                                                     │                                                     │
        └─────────────────────────────────────────────────────┴─────────────────────────────────────────────────────┘
                                                              │
                                                              ▼
                                                   [ Partner Finance Ledger ]
                                                   (Net Earnings & Available Balance)
                                                              │
                                                              ▼
                                                   [ Request Payout Settlement ]
                                                   (Bank Transfer Processing)
```

---

## 3. Admin Operations Console Flow

```
[ Admin Login ] ──► [ Platform Dashboard Metrics ]
                          │
     ┌────────────────────┼────────────────────┬────────────────────┐
     ▼                    ▼                    ▼                    ▼
[ KYC Review ]    [ Audit Logs ]      [ Finance Ledger ]   [ Webhook Logs ]
(Approve/Reject)  (Track Actors)      (Reconciliation)     (Inspect & Retry)
     │                                         │                    │
     ▼                                         ▼                    ▼
[ Activate Org ]                      [ Partner Adjustments ] [ Re-queue Event ]
                                      (Issue Credit/Debit)    (BullMQ Retry)
```

---

## 4. Failure & Edge-Case Journeys

### Edge Case 1: GPS Permission Denied by Customer
- **Flow**: App detects permission denied. Replaces GPS badge with selected City name (e.g. "Hyderabad"). Queries `/discovery/venues/nearby` or `/discovery/venues` using City ID fallback. Discovery continues seamlessly without crash or forced permission loops.

### Edge Case 2: Concurrent Court Reservation Attempt (Double Booking Race)
- **Flow**: Two customers attempt to book the same court slot simultaneously. First request enters PostgreSQL `Serializable` transaction and succeeds (`status: PENDING`). Second request fails transaction check and receives HTTP 409 Conflict ("Slot no longer available").

### Edge Case 3: Out-of-Order Webhook Delivery (Refund Arrives Before Capture)
- **Flow**: Webhook worker receives `refund.processed` before `payment.captured`. Webhook processor detects missing captured state, flags state anomaly, and stores event in `PaymentWebhookEvent` with `status: FAILED` and `lastError`. BullMQ retries the job 1,000ms later after `payment.captured` has completed.

### Edge Case 4: Invalid Webhook Gateway Signature (Tampered Request)
- **Flow**: Malicious user posts fake payload to `/api/v1/webhooks/razorpay`. `WebhooksService` computes HMAC-SHA256 signature against `RAZORPAY_WEBHOOK_SECRET`. Signature fails validation. Request is immediately rejected with HTTP 400 Bad Request and an audit log (`webhook:invalid_signature`) is recorded.

### Edge Case 5: Payout Request Exceeding Available Balance
- **Flow**: Partner attempts to request payout of ₹10,000 when available net payable balance is ₹6,000. `PayoutService` validates amount against `getPartnerFinancialSummary(orgId)`. Request is rejected with HTTP 400 ("Requested payout amount exceeds available balance").
