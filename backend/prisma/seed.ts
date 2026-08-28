import { PrismaClient, AccountStatus, BusinessStatus, VenueStatus, FacilityStatus } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const passwordHash = await bcrypt.hash('Password@123', 10);

  // 1. Cities
  const hyd = await prisma.city.upsert({
    where: { slug: 'hyderabad' },
    update: {},
    create: { name: 'Hyderabad', slug: 'hyderabad', state: 'Telangana' },
  });

  await prisma.city.upsert({
    where: { slug: 'bangalore' },
    update: {},
    create: { name: 'Bangalore', slug: 'bangalore', state: 'Karnataka' },
  });

  // 2. Categories
  const sports = await prisma.category.upsert({
    where: { slug: 'sports' },
    update: {},
    create: { name: 'Sports', slug: 'sports', icon: 'sports_soccer' },
  });

  // 3. Activities
  const football = await prisma.activity.upsert({
    where: { categoryId_slug: { categoryId: sports.id, slug: 'football' } },
    update: {},
    create: { name: 'Football', slug: 'football', categoryId: sports.id },
  });

  await prisma.activity.upsert({
    where: { categoryId_slug: { categoryId: sports.id, slug: 'cricket' } },
    update: {},
    create: { name: 'Cricket', slug: 'cricket', categoryId: sports.id },
  });

  // 4. Test User
  const user = await prisma.user.upsert({
    where: { email: 'testuser@playhub.com' },
    update: {},
    create: {
      email: 'testuser@playhub.com',
      fullName: 'Test User',
      passwordHash,
      status: AccountStatus.ACTIVE,
      isEmailVerified: true,
    },
  });

  // 5. Organization
  const org = await prisma.organization.upsert({
    where: { slug: 'test-org' },
    update: {},
    create: {
      name: 'Test Organization',
      slug: 'test-org',
    },
  });

  // 6. Membership
  await prisma.membership.upsert({
    where: { userId_organizationId: { userId: user.id, organizationId: org.id } },
    update: {},
    create: {
      userId: user.id,
      organizationId: org.id,
    },
  });

  // 7. Business
  const business = await prisma.business.create({
    data: {
      organizationId: org.id,
      legalName: 'Test Business Legal',
      displayName: 'Test Business',
      status: BusinessStatus.ACTIVE,
    },
  });

  // 8. Venue
  const venue = await prisma.venue.create({
    data: {
      businessId: business.id,
      cityId: hyd.id,
      name: 'Test Venue',
      slug: 'test-venue',
      address: 'Test Address',
      city: 'Hyderabad',
      state: 'Telangana',
      country: 'India',
      postalCode: '500001',
      status: VenueStatus.ACTIVE,
      operatingHours: {
        create: [
          { dayOfWeek: 'MONDAY', openingTime: '00:00', closingTime: '23:59' },
          { dayOfWeek: 'TUESDAY', openingTime: '00:00', closingTime: '23:59' },
          { dayOfWeek: 'WEDNESDAY', openingTime: '00:00', closingTime: '23:59' },
          { dayOfWeek: 'THURSDAY', openingTime: '00:00', closingTime: '23:59' },
          { dayOfWeek: 'FRIDAY', openingTime: '00:00', closingTime: '23:59' },
          { dayOfWeek: 'SATURDAY', openingTime: '00:00', closingTime: '23:59' },
          { dayOfWeek: 'SUNDAY', openingTime: '00:00', closingTime: '23:59' },
        ]
      }
    },
  });

  // 9. Facility
  const facility = await prisma.facility.create({
    data: {
      venueId: venue.id,
      categoryId: sports.id,
      activityId: football.id,
      name: 'Test Football Pitch',
      capacity: 10,
      status: FacilityStatus.ACTIVE,
    },
  });

  // 10. Pricing Rule
  await prisma.pricingRule.create({
    data: {
      facilityId: facility.id,
      name: 'Standard Hourly Rate',
      basePrice: 1000,
      currency: 'INR',
    },
  });

  console.log('Seed completed successfully with test data');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
