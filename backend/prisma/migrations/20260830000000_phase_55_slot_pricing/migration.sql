-- DropIndex
DROP INDEX "operating_hours_venueId_dayOfWeek_key";

-- AlterTable
ALTER TABLE "availability_blocks" ADD COLUMN     "dayOfWeek" "DayOfWeek",
ADD COLUMN     "isRecurring" BOOLEAN NOT NULL DEFAULT false;

-- AlterTable
ALTER TABLE "bookings" ADD COLUMN     "priceSnapshot" JSONB;

-- AlterTable
ALTER TABLE "facilities" ADD COLUMN     "defaultSlotDuration" INTEGER NOT NULL DEFAULT 60,
ADD COLUMN     "supportedSlotDurations" INTEGER[];

-- AlterTable
ALTER TABLE "pricing_rules" ADD COLUMN     "daysOfWeek" "DayOfWeek"[],
ADD COLUMN     "endTime" TEXT,
ADD COLUMN     "isActive" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN     "priority" INTEGER NOT NULL DEFAULT 0,
ADD COLUMN     "startTime" TEXT;

-- CreateIndex
CREATE INDEX "operating_hours_venueId_dayOfWeek_idx" ON "operating_hours"("venueId", "dayOfWeek");
