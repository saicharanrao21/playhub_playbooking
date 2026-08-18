# Production Deployment Readiness Guide

Use this checklist before deploying PlayHub to a production environment.

## 🏗️ Backend Preparation

### 1. Build and Environment
- [ ] Run `npm run build` to verify the production build.
- [ ] Ensure `NODE_ENV` is set to `production`.
- [ ] Configure `CORS_ORIGINS` with specific allowed domains (e.g., `https://app.playhub.com`).
- [ ] Verify `JWT_ACCESS_SECRET` and `JWT_REFRESH_SECRET` are long, secure strings.
- [ ] Tune `THROTTLE_TTL` and `THROTTLE_LIMIT` based on expected traffic.

### 2. Database (PostgreSQL)
- [ ] Use a managed database service (e.g., RDS, Cloud SQL) with backups enabled.
- [ ] Run `npx prisma migrate deploy` for production database schema updates.
- [ ] Verify that the `btree_gist` extension is enabled on the target database for concurrency constraints.
- [ ] Encrypt the connection using SSL.

### 3. Networking and SSL
- [ ] Ensure all API calls are made over HTTPS.
- [ ] Configure a load balancer or reverse proxy (Nginx) to handle SSL termination.
- [ ] Update `API_PREFIX` if necessary (defaults to `api/v1`).

---

## 📱 Flutter Release Preparation

### 1. App Configuration
- [ ] Set the production backend URL in the bootstrap configuration.
- [ ] Ensure no debug-only providers or mock repositories are active.
- [ ] Set `uses-material-design: true` in `pubspec.yaml`.

### 2. Platform Specifics
- [ ] **Android**: Configure Proguard/R8 rules. Sign the APK/App Bundle.
- [ ] **iOS**: Configure signing certificates and provisioning profiles in Xcode.
- [ ] **Web**: Verify the service worker and web renderer (`--web-renderer html` or `canvaskit`).

---

## 💳 Payment & Webhooks
- [ ] Switch Razorpay/Stripe keys to production mode.
- [ ] Configure production Webhook URLs in provider dashboards.
- [ ] Ensure `RAZORPAY_WEBHOOK_SECRET` and `STRIPE_WEBHOOK_SECRET` match the production dashboard values.

---

## 🛡️ Monitoring & Audit
- [ ] Check `/health` and `/health/readiness` endpoints.
- [ ] Verify that audit logging is active and correctly sanitizing sensitive data.
- [ ] Monitor error logs for `VALIDATION_ERROR` or `RESOURCE_CONFLICT` spikes.
