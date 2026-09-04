-- CreateIndex
CREATE INDEX "venues_latitude_longitude_idx" ON "venues"("latitude", "longitude");

-- CreateIndex
CREATE INDEX "venues_status_latitude_longitude_idx" ON "venues"("status", "latitude", "longitude");
