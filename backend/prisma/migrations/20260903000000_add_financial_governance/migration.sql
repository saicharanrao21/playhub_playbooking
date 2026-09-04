-- DropIndex
DROP INDEX IF EXISTS "commission_configs_organizationId_key";

-- AlterTable
ALTER TABLE "commission_configs" ADD COLUMN     "effectiveFrom" TIMESTAMP(3),
ADD COLUMN     "effectiveTo" TIMESTAMP(3),
ADD COLUMN     "name" TEXT NOT NULL DEFAULT 'Commission Rule',
ADD COLUMN     "priority" INTEGER NOT NULL DEFAULT 0;

-- AlterTable
ALTER TABLE "financial_transactions" ADD COLUMN     "createdById" TEXT,
ADD COLUMN     "reversalOfId" TEXT;

-- CreateIndex
CREATE INDEX "commission_configs_organizationId_isActive_idx" ON "commission_configs"("organizationId", "isActive");

-- CreateIndex
CREATE INDEX "financial_transactions_reversalOfId_idx" ON "financial_transactions"("reversalOfId");

-- AddForeignKey
ALTER TABLE "financial_transactions" ADD CONSTRAINT "financial_transactions_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "financial_transactions" ADD CONSTRAINT "financial_transactions_reversalOfId_fkey" FOREIGN KEY ("reversalOfId") REFERENCES "financial_transactions"("id") ON DELETE SET NULL ON UPDATE CASCADE;
