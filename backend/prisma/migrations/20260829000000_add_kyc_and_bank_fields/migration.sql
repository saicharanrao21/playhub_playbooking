-- CreateEnum
CREATE TYPE "KYCStatus" AS ENUM ('DRAFT', 'SUBMITTED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED', 'RESUBMISSION_REQUIRED');

-- AlterTable
ALTER TABLE "organizations" ADD COLUMN     "accountHolderName" TEXT,
ADD COLUMN     "accountNumber" TEXT,
ADD COLUMN     "bankName" TEXT,
ADD COLUMN     "gstNumber" TEXT,
ADD COLUMN     "ifscCode" TEXT,
ADD COLUMN     "kycStatus" "KYCStatus" NOT NULL DEFAULT 'DRAFT',
ADD COLUMN     "panNumber" TEXT;
