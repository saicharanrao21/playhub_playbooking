# PlayHub: Sports & Activity Booking Platform

PlayHub is a production-grade, multi-tenant platform for managing and booking sports venues and facilities. Built with a Flutter frontend and NestJS backend, it offers a secure, scalable, and concurrency-safe environment for venue operators and customers.

## 🚀 Overview

- **Multi-Tenant Architecture**: Complete isolation between organizations.
- **Booking Engine**: Concurrency-safe slot reservation with support for rescheduling and cancellation.
- **Availability Engine**: Real-time slot generation based on operating hours, closures, and blocks.
- **Payment Integration**: Secure payment foundation supporting Razorpay and Stripe.
- **Security First**: JWT-based auth, refresh token rotation, RBAC, and rate limiting.
- **Developer Friendly**: Full Swagger documentation and automated tests.

---

## 📂 Project Structure

- `backend/`: NestJS, Prisma, PostgreSQL.
- `lib/`: Flutter (Riverpod state management, GoRouter navigation).
- `docs/`: Detailed technical documentation.

---

## 🛠️ Getting Started

### Prerequisites

- **Node.js**: v18 or higher
- **npm**: v9 or higher
- **Flutter**: Latest stable
- **PostgreSQL**: Local or Docker instance
- **Prisma CLI**: `npm install -g prisma`

### 1. Backend Setup

1. **Navigate to backend**:
   ```bash
   cd backend
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Configure Environment**:
   Copy `.env.example` to `.env` and fill in your database and provider credentials.

4. **Initialize Database**:
   ```bash
   npx prisma generate
   npx prisma migrate dev
   ```

5. **Run the server**:
   ```bash
   npm run start:dev
   ```
   - API: `http://localhost:3000/api/v1`
   - Swagger Docs: `http://localhost:3000/docs`

### 2. Flutter Setup

1. **Install dependencies**:
   ```bash
   flutter pub get
   ```

2. **Run the app**:
   ```bash
   flutter run
   ```

---

## 🧪 Testing & Validation

### Backend
- **Run Unit Tests**: `npm test`
- **Build Check**: `npm run build`
- **Prisma Validation**: `npx prisma validate`

### Flutter
- **Analyze**: `flutter analyze`
- **Test**: `flutter test`

---

## 📘 Documentation

For detailed guides, refer to the `docs/` directory:
- [Architecture Overview](./docs/architecture/backend.md)
- [Multi-Tenancy](./docs/architecture/multi-tenancy.md)
- [Booking Engine](./docs/architecture/booking-engine.md)
- [Payment System Setup](./docs/architecture/payment-system.md)
- [Security Hardening](./docs/architecture/security.md)

---

## 🛡️ Production Readiness

- **Health Checks**: `/health` (liveness) and `/health/readiness` (database check).
- **Rate Limiting**: Enabled globally.
- **Sanitized Logging**: Sensitive data (passwords, tokens, CVV) are automatically redacted.
- **Atomic Transactions**: All booking and payment state changes use `Serializable` transactions.
