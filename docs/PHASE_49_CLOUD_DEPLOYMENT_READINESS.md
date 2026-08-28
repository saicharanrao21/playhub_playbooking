# Phase 49: Cloud Deployment Readiness

## 1. Initial Deployment Audit
- **Root Structure**: Monorepo with `backend/` and `lib/` (Flutter).
- **Backend**: NestJS application with Prisma ORM.
- **Port Handling**: `main.ts` listens on `process.env.PORT` or defaults to 3000.
- **Database**: DATABASE_URL is injected via environment variables.
- **CORS**: Environment-driven `CORS_ORIGINS`.
- **Health Check**: `GET /api/v1/health` and `GET /api/v1/health/readiness` already implemented.

## 2. Architecture Findings
The backend is stateless and suitable for containerized deployment (e.g., Railway, Heroku, AWS ECS). Static media is currently using `local` storage, which will not persist across container restarts in most cloud environments.

## 3. Database Migration Strategy
- **Command**: `npm run prisma:migrate:deploy`
- **Deployment Flow**: The `Dockerfile` has been updated to use `start:prod:migrate` which runs migrations before starting the app. This ensures the managed database is always in sync with the repository schema.

## 4. Docker Findings
- **Base Image**: `node:20-alpine` for both build and runtime.
- **Security**: Runs as non-root `node` user.
- **Prisma**: `npx prisma generate` is executed during the build stage.

## 5. Environment Variable Requirements
Required for successful boot in production:
- `NODE_ENV`: `production`
- `PORT`: (Injected by host)
- `DATABASE_URL`: (Connection string to managed PostgreSQL)
- `JWT_ACCESS_SECRET`: (Minimum 32 characters)
- `JWT_REFRESH_SECRET`: (Minimum 32 characters)
- `API_PREFIX`: `api/v1`

Optional but recommended:
- `CORS_ORIGINS`: Commas-separated list of allowed frontend domains.
- `RESEND_API_KEY`: For production email delivery.
- `RAZORPAY_KEY_ID` / `RAZORPAY_KEY_SECRET`: For real payments.

## 6. Health Check Status
- **Liveness**: `GET /api/v1/health` returns `status: ok`.
- **Readiness**: `GET /api/v1/health/readiness` performs a `SELECT 1` on the database.

## 7. CORS Strategy
In development, CORS is open. In production, it checks against `CORS_ORIGINS` environment variable.

## 8. Media Production Status
**LIMITATION**: Currently configured for `local` storage. For true production deployment, `MEDIA_STORAGE_PROVIDER` should be switched to `s3` once an S3-compatible bucket (AWS S3, DigitalOcean Spaces, Supabase Storage) is available.

## 9. Payment & Communication Safety
- **Payments**: Application boots safely without credentials. Production disallows mock providers.
- **Communication**: Mock providers are explicitly blocked in production (`NODE_ENV=production`).

## 10. Exact Cloud Deployment Steps (e.g., Railway)
1. Link GitHub repository to Railway.
2. Add a PostgreSQL service.
3. Set the Root Directory to `backend/`.
4. Configure Environment Variables in Railway dashboard.
5. Railway will detect the `Dockerfile` and build/deploy automatically.
6. Deployment will trigger `prisma migrate deploy` automatically.

## 11. Validation Results
- **Backend Build**: SUCCESS
- **Prisma Validation**: SUCCESS
- **Backend Tests**: 61/61 Passed
- **Flutter Analyze**: SUCCESS (Standard deprecation warnings only)
