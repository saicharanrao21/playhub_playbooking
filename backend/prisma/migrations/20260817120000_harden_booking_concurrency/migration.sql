-- CreateExtension
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- AddExclusionConstraint
-- Prevents overlapping PENDING or CONFIRMED bookings for the same facility.
-- Semantics: [startTime, endTime) half-open interval.
ALTER TABLE "bookings" ADD CONSTRAINT "no_overlapping_bookings" EXCLUDE USING gist (
  "facilityId" WITH =,
  tstzrange("startTime", "endTime") WITH &&
) WHERE ("status" != 'CANCELLED');
