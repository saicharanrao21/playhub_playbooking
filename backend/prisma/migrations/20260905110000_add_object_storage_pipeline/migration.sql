-- AlterTable
ALTER TABLE "media" ADD COLUMN     "bucket" TEXT,
ADD COLUMN     "category" TEXT NOT NULL DEFAULT 'VENUE_MEDIA',
ADD COLUMN     "checksum" TEXT,
ADD COLUMN     "entityId" TEXT,
ADD COLUMN     "entityType" TEXT,
ADD COLUMN     "status" TEXT NOT NULL DEFAULT 'UPLOAD_PENDING',
ADD COLUMN     "storageProvider" TEXT NOT NULL DEFAULT 's3',
ADD COLUMN     "visibility" TEXT NOT NULL DEFAULT 'PUBLIC';

-- CreateIndex
CREATE INDEX "media_category_idx" ON "media"("category");

-- CreateIndex
CREATE INDEX "media_status_idx" ON "media"("status");

-- CreateIndex
CREATE INDEX "media_entityType_entityId_idx" ON "media"("entityType", "entityId");
