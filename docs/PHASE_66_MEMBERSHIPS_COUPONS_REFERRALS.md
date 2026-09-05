# PlayHub Phase 66: Memberships, Coupons & Referral Loyalty Engine

## 1. Executive Summary
Phase 66 implements a production-grade **Memberships, Promo Coupons, Referral Engine, and Loyalty Ledger System** for PlayHub. The architecture supports organization-specific and platform-wide membership plans with structured benefits, a transaction-safe coupon validation and redemption pipeline with strict usage limits, a referral attribution system with self-referral prevention and idempotent rewards, and an immutable double-entry loyalty points ledger (`EARN`, `REDEEM`, `BONUS`, `REFERRAL`, `EXPIRY`, `ADMIN_ADJUSTMENT`).

## 2. Core Domain Architecture

### A. Membership Engine
- **`MembershipPlan`**: Organization-scoped or global plans (`code`, `price`, `duration`, `durationUnit`, `benefits`).
- **`CustomerMembership`**: Customer subscription tracking (`startDate`, `expiryDate`, `status`: `ACTIVE`, `EXPIRING`, `EXPIRED`, `CANCELLED`).

### B. Coupon Engine & Validation Pipeline
- **`Coupon`**: `discountType` (`PERCENTAGE` / `FIXED`), `minBookingAmount`, `maxDiscountAmount`, `validFrom`, `validTo`, `totalRedemptionLimit`, `perUserRedemptionLimit`, `firstBookingOnly`, `membershipRequired`.
- **`CouponRedemption`**: Atomic redemption record linked to booking and user.
- **Validation Pipeline**: Server-authoritative validation verifying date ranges, min spend, total usage limits, per-user limits, first-booking status, and active membership requirements before computing final payable amount.

### C. Referral Engine & Campaign Rewards
- **`ReferralCode`**: Unique readable code generated for user (`PLAY-A8B9`).
- **`Referral` & `ReferralCampaign`**:
  - Blocks self-referral (`referrerId != refereeId`).
  - Idempotent qualification upon referee's first booking (`status: QUALIFIED`).
  - Awards 100 points to referrer and 50 bonus points to referee.

### D. Loyalty Points Ledger
- **`LoyaltyAccount` & `LoyaltyTransaction`**:
  - `pointsBalance` and `lifetimeEarned` updated atomically.
  - Immutable transactions (`EARN`, `REDEEM`, `BONUS`, `REFERRAL`, `EXPIRY`, `ADMIN_ADJUSTMENT`).
  - 1 Point = ₹1 Court Discount redemption.

## 3. Database Schema & Migration
- Migration `20260905120000_add_memberships_coupons_loyalty` applied:
  - Created `membership_plans`, `customer_memberships`, `coupons`, `coupon_redemptions`, `referral_codes`, `referral_campaigns`, `referrals`, `loyalty_accounts`, and `loyalty_transactions` tables.
  - Added indexes on codes, expiry dates, organization IDs, and user relationships.

## 4. Customer Flutter UX
- **Offers & Promo Coupons** (`lib/features/profile/presentation/screens/coupons_screen.dart`): Coupon codes list with 1-tap clipboard copying.
- **Memberships** (`lib/features/profile/presentation/screens/memberships_screen.dart`): Active membership card, plan details, and purchase integration.
- **Refer & Earn** (`lib/features/profile/presentation/screens/referral_screen.dart`): Referral code display (`PLAY-A8B9`), share/copy actions.
- **Loyalty Rewards** (`lib/features/profile/presentation/screens/loyalty_screen.dart`): Points balance banner (1 Pt = ₹1) & transaction ledger history.

## 5. Verification & Quality Results
- **Backend Unit Tests**: 29/29 Test Suites Passed (104 total tests passed).
- **Prisma Schema & Validation**: Valid (`npx prisma validate`).
- **NestJS Build**: Succeeded (`nest build`).
- **Flutter Analyze**: 0 issues found (`flutter analyze` clean).
- **Flutter Tests**: Passed.
- **Flutter Web Build**: Succeeded (`flutter build web --release`).
- **Regression Check**: Customer V3, Partner Workspace, Admin Operations Console, Geolocation, Redis, BullMQ, Observability, Object Storage, and Webhook resilience remain 100% operational.
