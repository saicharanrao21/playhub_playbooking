# PlayHub Deployment Guide

## Backend Deployment (NestJS + Prisma)

### Requirements
- Node.js 20.x
- PostgreSQL 15+
- Environment variables configured

### Required Environment Variables
| Variable | Description | Production Requirement |
|----------|-------------|-------------------------|
| `NODE_ENV` | Environment name | `production` |
| `PORT` | Listening port | e.g. `3000` |
| `DATABASE_URL` | PostgreSQL connection string | **REQUIRED** |
| `JWT_ACCESS_SECRET` | Secret for Access Token | **REQUIRED (32+ chars)** |
| `JWT_REFRESH_SECRET` | Secret for Refresh Token | **REQUIRED (32+ chars)** |
| `CORS_ORIGINS` | Allowed CORS origins | Comma-separated list |
| `PAYMENT_PROVIDER` | `RAZORPAY`, `STRIPE` or `MOCK` | Default `RAZORPAY` |
| `RAZORPAY_KEY_ID` | Razorpay Key ID | Optional (for payments) |
| `RAZORPAY_KEY_SECRET` | Razorpay Key Secret | Optional (for payments) |
| `RAZORPAY_WEBHOOK_SECRET` | Razorpay Webhook Secret | Optional |
| `STRIPE_SECRET_KEY` | Stripe Secret Key | Optional (for payments) |
| `STRIPE_WEBHOOK_SECRET` | Stripe Webhook Secret | Optional |
| `MEDIA_STORAGE_PROVIDER` | `local` or `s3` | Default `local` |
| `MEDIA_PUBLIC_BASE_URL` | Base URL for serving media | e.g. `https://cdn.playhub.com` |
| `STORAGE_S3_BUCKET` | S3 Bucket Name | Required if provider is `s3` |
| `STORAGE_S3_REGION` | S3 Region | Required if provider is `s3` |
| `STORAGE_LOCAL_DIR` | Local directory for uploads | Default `uploads` |

### Deployment Steps
1. **Infrastructure**: Provision a PostgreSQL database and a Node.js hosting environment (e.g. AWS ECS, Heroku, DigitalOcean App Platform).
2. **Environment**: Set all required environment variables in your hosting provider's dashboard.
3. **Build**: Run `npm install` followed by `npm run build` in the `backend/` directory.
4. **Prisma & Migration**:
   - Run `npx prisma generate` to build the client.
   - **Recommended**: Run `npm run prisma:migrate:deploy` as a separate release step/job before starting the application. 
   - Alternatively, if your platform doesn't support separate release steps, the Docker image can be configured to run it on startup by changing the CMD to `npm run start:prod:migrate`.
5. **Start**: Run `npm run start:prod` (executes `node dist/main`).

### Docker Deployment
A `Dockerfile` is provided in the `backend/` directory for containerized deployments.
```bash
docker build -t playhub-backend ./backend
docker run -p 3000:3000 --env-file .env playhub-backend
```

## Failure and Rollback Guidance

### Migration Failure
If `prisma migrate deploy` fails:
1. **STOP** the deployment immediately.
2. Inspect logs to determine if the failure is due to a connection issue or a schema conflict.
3. If it's a conflict, do NOT manually edit the `_prisma_migrations` table unless absolutely necessary.
4. Fix the issue and re-run migrations.

### Application Startup Failure
If the application fails to start or fails readiness checks:
1. Check if all environment variables are correctly set.
2. Verify database connectivity via the readiness logs.
3. **Rollback**: Redeploy the previous stable Docker image version. Prisma migrations are generally backward compatible if designed carefully.

## Staging Smoke Test Plan
Perform these steps after a successful staging deployment:

1. **Health**: Confirm `/api/v1/health` and `/api/v1/health/readiness` return `ok` and `ready`.
2. **Auth**: Register a new user, log in, and verify the session persists.
3. **Tenant**: Verify you can see your organization context and cannot access other organizations.
4. **Booking**: Search for a venue, check availability, and create a booking.
5. **Payment**: Initiate a payment order. Verify the transition to `PENDING`.
6. **Cancellation**: Cancel a booking and verify the status update.

## Flutter Deployment

### Requirements
- Flutter SDK (Stable channel)
- Android Studio / Xcode for platform-specific builds

### Build with Environment Variables
Use `--dart-define` to configure the environment at build time.
- `APP_ENV`: `local`, `dev`, `staging`, or `prod` (default: `dev`).
- `API_BASE_URL`: Override the default API URL.

#### Android Staging Build Example
```bash
flutter build apk --release --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://staging-api.playhub.com/api/v1
```

### Build Commands
#### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```
#### iOS
```bash
flutter build ios --release
```

## Security Best Practices
- **Secrets**: Never commit `.env` files. Use secret management tools provided by your cloud provider.
- **HTTPS**: Always serve the API and the web version over HTTPS.
- **CORS**: Restrict `CORS_ORIGINS` to your actual frontend domain in production.
- **Database**: Ensure the database is not publicly accessible; use a VPC or restricted IP access.
