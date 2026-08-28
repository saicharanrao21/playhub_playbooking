# Build stage
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
COPY prisma ./prisma/
RUN npm ci
COPY . .
RUN npm run build
RUN npx prisma generate

# Production stage
FROM node:20-alpine
WORKDIR /app
# Install openssl for Prisma
RUN apk add --no-cache openssl
COPY --chown=node:node --from=builder /app/package*.json ./
COPY --chown=node:node --from=builder /app/node_modules ./node_modules
COPY --chown=node:node --from=builder /app/dist ./dist
COPY --chown=node:node --from=builder /app/prisma ./prisma
RUN mkdir -p /app/uploads && chown -R node:node /app
USER node
EXPOSE 3000
ENV NODE_ENV=production

# By default, run migrations and then start the app.
# This ensures the database is always in sync with the current schema on deployment.
CMD ["npm", "run", "start:prod:migrate"]

