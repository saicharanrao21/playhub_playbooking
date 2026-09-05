-- AlterTable
ALTER TABLE "payment_webhook_events" ADD COLUMN     "failedAt" TIMESTAMP(3),
ADD COLUMN     "lastError" TEXT,
ADD COLUMN     "organizationId" TEXT,
ADD COLUMN     "processingStartedAt" TIMESTAMP(3),
ADD COLUMN     "receivedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN     "retryCount" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "signature" TEXT,
ADD COLUMN     "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
ALTER COLUMN "processedAt" DROP NOT NULL,
ALTER COLUMN "processedAt" DROP DEFAULT,
ALTER COLUMN "status" SET DEFAULT 'RECEIVED';

-- CreateIndex
CREATE INDEX "payment_webhook_events_status_idx" ON "payment_webhook_events"("status");

-- CreateIndex
CREATE INDEX "payment_webhook_events_paymentId_idx" ON "payment_webhook_events"("paymentId");

-- CreateIndex
CREATE INDEX "payment_webhook_events_organizationId_idx" ON "payment_webhook_events"("organizationId");

-- CreateIndex
CREATE INDEX "payment_webhook_events_createdAt_idx" ON "payment_webhook_events"("createdAt");
