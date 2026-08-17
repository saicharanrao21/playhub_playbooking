# PlayHub Platform Backend

The authoritative backend foundation for the PlayHub platform. Built with NestJS, Prisma, and PostgreSQL.

## Core Stack
- **Framework:** [NestJS](https://nestjs.com/)
- **Language:** TypeScript
- **Database:** PostgreSQL
- **ORM:** [Prisma](https://www.prisma.io/)
- **Security:** JWT (Access + Refresh tokens), Bcrypt, Helmet, CORS
- **Documentation:** OpenAPI (Swagger)

## Getting Started

### Prerequisites
- Node.js (v18+)
- npm
- Docker (for local PostgreSQL/Redis)

### Setup
1. Copy `.env.example` to `.env` and update values.
2. Install dependencies:
   ```bash
   npm install
   ```
3. Generate Prisma client:
   ```bash
   npm run prisma:generate
   ```
4. Run migrations:
   ```bash
   npm run prisma:migrate
   ```

### Running the App
```bash
# Development
npm run start:dev

# Production build
npm run build
npm run start:prod
```

## API Documentation
Once the server is running, visit:
`http://localhost:3000/docs`

## Architecture Principles
1. **Modular Monolith:** Logic is grouped by domain (Users, Auth, Organizations).
2. **Multi-tenancy:** All resources are scoped to an Organization.
3. **Zero Trust Client:** All validation and authorization happen server-side.
4. **Audit Trail:** Critical actions are logged to `audit_logs`.
