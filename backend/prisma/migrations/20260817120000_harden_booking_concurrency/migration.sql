-- CreateExtension
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- AddExclusionConstraint
-- Prevents overlapping PENDING or CONFIRMED bookings for the same facility.
-- Semantics: [startTime, endTime) half-open interval.
-- NOTE: Changed from tstzrange to tsrange because Prisma DateTime maps to 'timestamp without time zone'.
ALTER TABLE "bookings" ADD CONSTRAINT "no_overlapping_bookings" EXCLUDE USING gist (
  "facilityId" WITH =,
  tsrange("startTime", "endTime") WITH &&
) WHERE ("status" != 'CANCELLED');
