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
| `RAZORPAY_KEY_ID` | Razorpay Key ID | Optional (for payments) |
| `RAZORPAY_KEY_SECRET` | Razorpay Key Secret | Optional (for payments) |
| `STRIPE_SECRET_KEY` | Stripe Secret Key | Optional (for payments) |

### Deployment Steps
1. **Infrastructure**: Provision a PostgreSQL database and a Node.js hosting environment (e.g. AWS ECS, Heroku, DigitalOcean App Platform).
2. **Environment**: Set all required environment variables in your hosting provider's dashboard.
3. **Build**: Run `npm install` followed by `npm run build` in the `backend/` directory.
4. **Prisma**:
   - Run `npx prisma generate` to build the client.
   - Run `npx prisma migrate deploy` to apply migrations to the production database.
5. **Start**: Run `npm run start:prod` (executes `node dist/main`).

### Docker Deployment
A `Dockerfile` is provided in the `backend/` directory for containerized deployments.
```bash
docker build -t playhub-backend ./backend
docker run -p 3000:3000 --env-file .env playhub-backend
```

## Flutter Deployment

### Requirements
- Flutter SDK (Stable channel)
- Android Studio / Xcode for platform-specific builds

### Configuration
1. Update `lib/core/config/env_config.dart` with your production API URL if different from the default.
2. Ensure you have the necessary signing keys for Android (`key.properties`) and iOS.

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
