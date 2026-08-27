# Phase 48: Communication & Notification Infrastructure

## 1. Overview
Implemented a provider-independent communication layer supporting In-App, Email, SMS, WhatsApp, and Push notifications. The system uses a centralized `CommunicationService` and event listeners to decouple business logic from specific communication providers.

## 2. Architecture
- **Centralized Entry Point**: `CommunicationService` handles logging, preference checks, and routing to specific providers.
- **Event-Driven**: `CommunicationEventsListener` listens for backend events (e.g., `BOOKING_CONFIRMED`, `PAYMENT_CAPTURED`) and triggers appropriate channels.
- **Provider Abstraction**: Interfaces for `EmailProvider`, `SmsProvider`, `WhatsAppProvider`, and `PushProvider` allow easy vendor replacement.
- **Reliability**: All communications are logged to `CommunicationLog` table with delivery status tracking and error recording.
- **Preferences**: Users can control which channels they receive notifications through per category (Transactional, Marketing).

## 3. Supported Channels & Providers

| Channel | Implementation | Provider | Status |
|:---|:---|:---|:---|
| **In-App** | Native Prisma model | Internal | **COMPLETE** |
| **Email** | Resend API | Resend | **PRODUCTION READY** |
| **SMS** | Mock Provider | Mock | **ARCHITECTED** |
| **WhatsApp** | Mock Provider | Mock | **ARCHITECTED** |
| **Push** | Device Registration + Mock | Mock | **ARCHITECTED** |

## 4. Key Features
- **Device Management**: Backend stores device tokens linked to users with platform info.
- **Template System**: `TemplateRegistry` centralizes user-facing messages, preventing hardcoded strings in services.
- **Transactional Safety**: Communication failures do not affect the integrity of core business transactions (Bookings/Payments).
- **Tenant Isolation**: Logs and communications respect `organizationId` boundaries where applicable.

## 5. Required External Configuration
- `RESEND_API_KEY`: Required for transactional emails.
- `EMAIL_FROM`: Default sender identity (e.g., `PlayHub <notifications@playhub.app>`).
- `FIREBASE_SERVICE_ACCOUNT`: Required later for production FCM activation.

## 6. Security Controls
- **IDOR Protection**: Users can only register their own devices and modify their own preferences.
- **Sanitized Logging**: Failure reasons are recorded but sensitive provider internals are not exposed to the client.
- **Transaction/Marketing Split**: Users can opt out of marketing without missing critical booking/payment updates.

---
**Status**: ARCHITECTURE COMPLETE. Code ready for production email activation.
