-- Seed Cities
INSERT INTO "cities" ("id", "name", "slug", "state", "country", "isActive", "createdAt", "updatedAt")
VALUES 
  ('city_hyd_001', 'Hyderabad', 'hyderabad', 'Telangana', 'India', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('city_blr_001', 'Bangalore', 'bangalore', 'Karnataka', 'India', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("slug") DO NOTHING;

-- Seed Categories
INSERT INTO "categories" ("id", "name", "slug", "icon", "isActive", "createdAt", "updatedAt")
VALUES 
  ('cat_sports_001', 'Sports', 'sports', 'sports_soccer', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("slug") DO NOTHING;

-- Seed Activities
INSERT INTO "activities" ("id", "categoryId", "name", "slug", "icon", "isActive", "createdAt", "updatedAt")
VALUES 
  ('act_football_001', (SELECT "id" FROM "categories" WHERE "slug" = 'sports' LIMIT 1), 'Football', 'football', 'sports_soccer', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('act_cricket_001', (SELECT "id" FROM "categories" WHERE "slug" = 'sports' LIMIT 1), 'Cricket', 'cricket', 'sports_cricket', true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("categoryId", "slug") DO NOTHING;

-- Seed Roles
INSERT INTO "roles" ("id", "name", "description", "createdAt", "updatedAt")
VALUES 
  ('role_admin_001', 'ADMIN', 'Platform & Organization Administrator', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('role_biz_owner_001', 'BUSINESS_OWNER', 'Business Owner', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('role_customer_001', 'CUSTOMER', 'End User / Customer', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("name") DO NOTHING;

-- Seed Permissions
INSERT INTO "permissions" ("id", "action", "resource", "description", "createdAt", "updatedAt")
VALUES 
  ('perm_01', 'read', 'organization', 'Read organization', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_02', 'update', 'organization', 'Update organization', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_03', 'create', 'business', 'Create business', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_04', 'read', 'business', 'Read business', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_05', 'update', 'business', 'Update business', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_06', 'delete', 'business', 'Delete business', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_07', 'create', 'venue', 'Create venue', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_08', 'read', 'venue', 'Read venue', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_09', 'update', 'venue', 'Update venue', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_10', 'delete', 'venue', 'Delete venue', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_11', 'create', 'facility', 'Create facility', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_12', 'read', 'facility', 'Read facility', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_13', 'update', 'facility', 'Update facility', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_14', 'delete', 'facility', 'Delete facility', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_15', 'create', 'availability_block', 'Create availability block', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_16', 'read', 'availability_block', 'Read availability block', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_17', 'delete', 'availability_block', 'Delete availability block', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_18', 'read', 'booking', 'Read booking', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_19', 'update', 'booking', 'Update booking', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_20', 'delete', 'booking', 'Delete booking', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_21', 'read', 'payment', 'Read payment', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_22', 'update', 'payment', 'Update payment', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_23', 'read', 'organization_settings', 'Read settings', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_24', 'create', 'city', 'Create city', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_25', 'update', 'city', 'Update city', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_26', 'create', 'category', 'Create category', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_27', 'update', 'category', 'Update category', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_28', 'create', 'activity', 'Create activity', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
  ('perm_29', 'update', 'activity', 'Update activity', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("action", "resource") DO NOTHING;

-- Map All Permissions to Admin Role
INSERT INTO "_RolePermissions" ("A", "B")
SELECT p."id", r."id"
FROM "permissions" p, "roles" r
WHERE r."name" = 'ADMIN'
ON CONFLICT DO NOTHING;

-- Seed Test User (Password@123)
-- bcrypt hash for Password@123: $2b$10$k8.BLYyIEReWxshYann7vOz6Smqn6lSQA.kmjlC/hyHu1/ZBanJ6y
INSERT INTO "users" ("id", "email", "fullName", "passwordHash", "status", "isEmailVerified", "isPhoneVerified", "createdAt", "updatedAt")
VALUES 
  ('usr_testuser_001', 'testuser@playhub.com', 'Test User', '$2b$10$k8.BLYyIEReWxshYann7vOz6Smqn6lSQA.kmjlC/hyHu1/ZBanJ6y', 'ACTIVE', true, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("email") DO UPDATE SET "passwordHash" = '$2b$10$k8.BLYyIEReWxshYann7vOz6Smqn6lSQA.kmjlC/hyHu1/ZBanJ6y', "status" = 'ACTIVE';

-- Seed Organization
INSERT INTO "organizations" ("id", "name", "slug", "status", "createdAt", "updatedAt")
VALUES 
  ('org_test_001', 'Test Organization', 'test-org', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("slug") DO NOTHING;

-- Seed Membership
INSERT INTO "memberships" ("id", "userId", "organizationId", "createdAt", "updatedAt")
VALUES 
  ('mem_test_001', (SELECT "id" FROM "users" WHERE "email" = 'testuser@playhub.com' LIMIT 1), (SELECT "id" FROM "organizations" WHERE "slug" = 'test-org' LIMIT 1), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("userId", "organizationId") DO NOTHING;

-- Map Admin Role to Test User Membership
INSERT INTO "_MembershipRoles" ("A", "B")
SELECT m."id", r."id"
FROM "memberships" m, "roles" r
WHERE m."id" = 'mem_test_001' AND r."name" = 'ADMIN'
ON CONFLICT DO NOTHING;

-- Seed Business
INSERT INTO "businesses" ("id", "organizationId", "legalName", "displayName", "status", "createdAt", "updatedAt")
VALUES 
  ('biz_test_001', 'org_test_001', 'Test Business Legal', 'Test Business', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("id") DO NOTHING;

-- Seed Venue
INSERT INTO "venues" ("id", "businessId", "cityId", "name", "slug", "description", "address", "city", "state", "country", "postalCode", "status", "createdAt", "updatedAt")
VALUES 
  ('ven_test_001', 'biz_test_001', (SELECT "id" FROM "cities" WHERE "slug" = 'hyderabad' LIMIT 1), 'Test Venue', 'test-venue', 'Premier sports venue in Hyderabad', 'Hitech City Main Road', 'Hyderabad', 'Telangana', 'India', '500081', 'ACTIVE', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("businessId", "slug") DO NOTHING;

-- Seed Operating Hours for Venue (7 days 00:00 to 23:59)
INSERT INTO "operating_hours" ("id", "venueId", "dayOfWeek", "openingTime", "closingTime", "isClosed")
VALUES 
  ('oph_mon_001', 'ven_test_001', 'MONDAY', '00:00', '23:59', false),
  ('oph_tue_001', 'ven_test_001', 'TUESDAY', '00:00', '23:59', false),
  ('oph_wed_001', 'ven_test_001', 'WEDNESDAY', '00:00', '23:59', false),
  ('oph_thu_001', 'ven_test_001', 'THURSDAY', '00:00', '23:59', false),
  ('oph_fri_001', 'ven_test_001', 'FRIDAY', '00:00', '23:59', false),
  ('oph_sat_001', 'ven_test_001', 'SATURDAY', '00:00', '23:59', false),
  ('oph_sun_001', 'ven_test_001', 'SUNDAY', '00:00', '23:59', false)
ON CONFLICT ("venueId", "dayOfWeek") DO NOTHING;

-- Seed Facility
INSERT INTO "facilities" ("id", "venueId", "categoryId", "activityId", "name", "description", "capacity", "status", "displayOrder", "createdAt", "updatedAt")
VALUES 
  ('fac_football_001', 'ven_test_001', (SELECT "id" FROM "categories" WHERE "slug" = 'sports' LIMIT 1), (SELECT "id" FROM "activities" WHERE "slug" = 'football' LIMIT 1), 'Test Football Pitch', 'FIFA-grade 5-a-side artificial turf', 10, 'ACTIVE', 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("id") DO NOTHING;

-- Seed Pricing Rule
INSERT INTO "pricing_rules" ("id", "facilityId", "name", "basePrice", "currency", "createdAt", "updatedAt")
VALUES 
  ('prc_football_001', 'fac_football_001', 'Standard Hourly Rate', 1000.00, 'INR', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
ON CONFLICT ("id") DO NOTHING;
