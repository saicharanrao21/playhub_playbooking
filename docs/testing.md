# Testing Documentation

PlayHub emphasizes reliability through automated testing across the backend and frontend.

---

## 🛠️ Backend Testing (NestJS)

We use **Jest** for unit and integration testing.

### 1. Run All Tests
```bash
cd backend
npm test
```

### 2. Run in Watch Mode
```bash
npm run test:watch
```

### 3. Generate Coverage Report
```bash
npm run test:cov
```

### 📋 Coverage Scope
- **AuthService**: Refresh token rotation, reuse detection, and session security.
- **BookingsService**: Concurrency safety (Serializable transactions), overlap detection, rescheduling, and cancellation logic.
- **AvailabilityService**: Slot generation, operating hours validation, and block handling.
- **PaymentsService**: State machine transitions, idempotency, and webhook processing.
- **Common Utilities**: Time interval math (subtraction, intersection).

---

## 📱 Flutter Testing

### 1. Static Analysis
Run the analyzer to check for linting issues and potential bugs:
```bash
flutter analyze
```

### 2. Run Unit & Widget Tests
```bash
flutter test
```

---

## 🛡️ Database Validation (Prisma)

Ensure the schema is consistent and the client is up to date:
```bash
cd backend
npx prisma validate
npx prisma generate
```

---

## 🏁 Quality Guardrails
1. **CI/CD**: Every push to `master` should ideally trigger the full test suite.
2. **Concurrency Tests**: Special attention is given to `BookingsService` to ensure no double-bookings occur under high load.
3. **Tenant Isolation**: Tests verify that users cannot access resources outside their organization context.
