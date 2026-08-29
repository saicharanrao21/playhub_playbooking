import { PrismaClient, AccountStatus, BusinessStatus, VenueStatus, FacilityStatus, OrganizationStatus, KYCStatus, DayOfWeek, BookingStatus } from '@prisma/client';
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

  const blr = await prisma.city.upsert({
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

  // 4. Partner User
  const partnerUser = await prisma.user.upsert({
    where: { email: 'partner@playhub.com' },
    update: {},
    create: {
      email: 'partner@playhub.com',
      fullName: 'Venkatesh Rao',
      passwordHash: passwordHash,
      status: AccountStatus.ACTIVE,
      isEmailVerified: true,
      phoneNumber: '+91 99999 88888',
    },
  });

  // 5. Partner Organization
  const partnerOrg = await prisma.organization.upsert({
    where: { slug: 'skyline-sports' },
    update: {},
    create: {
      name: 'Skyline Sports Hub',
      slug: 'skyline-sports',
      kycStatus: KYCStatus.APPROVED,
    },
  });

  // 6. Partner Membership
  let partnerRole = await prisma.role.findUnique({ where: { name: 'BUSINESS_OWNER' } });
  if (!partnerRole) {
    partnerRole = await prisma.role.create({
      data: { name: 'BUSINESS_OWNER', description: 'Business Owner' },
    });
  }

  await prisma.membership.upsert({
    where: { userId_organizationId: { userId: partnerUser.id, organizationId: partnerOrg.id } },
    update: {},
    create: {
      userId: partnerUser.id,
      organizationId: partnerOrg.id,
      roles: { connect: [{ id: partnerRole.id }] },
    },
  });

  // 7. Partner Business
  const partnerBusiness = await prisma.business.upsert({
    where: { id: 'biz_skyline_001' },
    update: {},
    create: {
      id: 'biz_skyline_001',
      organizationId: partnerOrg.id,
      legalName: 'Skyline Sports Ventures Pvt Ltd',
      displayName: 'Skyline Arena',
      status: BusinessStatus.ACTIVE,
    },
  });

  // 8. Partner Venue
  const venue = await prisma.venue.upsert({
    where: { businessId_slug: { businessId: partnerBusiness.id, slug: 'skyline-gachibowli' } },
    update: { timezone: 'Asia/Kolkata' },
    create: {
      businessId: partnerBusiness.id,
      cityId: hyd.id,
      name: 'Skyline Gachibowli',
      slug: 'skyline-gachibowli',
      address: 'Plot 42, Hitech City Main Road',
      city: 'Hyderabad',
      state: 'Telangana',
      country: 'India',
      postalCode: '500081',
      timezone: 'Asia/Kolkata',
      status: VenueStatus.ACTIVE,
      operatingHours: {
        create: [
          { dayOfWeek: 'MONDAY', openingTime: '06:00', closingTime: '23:00' },
          { dayOfWeek: 'TUESDAY', openingTime: '06:00', closingTime: '23:00' },
          { dayOfWeek: 'WEDNESDAY', openingTime: '06:00', closingTime: '23:00' },
          { dayOfWeek: 'THURSDAY', openingTime: '06:00', closingTime: '23:00' },
          { dayOfWeek: 'FRIDAY', openingTime: '06:00', closingTime: '23:00' },
          { dayOfWeek: 'SATURDAY', openingTime: '06:00', closingTime: '23:59' },
          { dayOfWeek: 'SUNDAY', openingTime: '06:00', closingTime: '23:59' },
        ]
      }
    },
  });

  // 9. Facility
  const facility = await prisma.facility.upsert({
    where: { id: 'fac_football_001' },
    update: { defaultSlotDuration: 60 },
    create: {
      id: 'fac_football_001',
      venueId: venue.id,
      categoryId: sports.id,
      activityId: football.id,
      name: 'Main Football Turf',
      capacity: 10,
      status: FacilityStatus.ACTIVE,
      defaultSlotDuration: 60,
    },
  });

  // 10. Pricing Rules (Phase 55 focus)
  await prisma.pricingRule.deleteMany({ where: { facilityId: facility.id } });

  await prisma.pricingRule.createMany({
    data: [
      {
        facilityId: facility.id,
        name: 'Base Weekday Rate',
        basePrice: 500,
        daysOfWeek: ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY'],
        priority: 0,
      },
      {
        facilityId: facility.id,
        name: 'Peak Hour Surcharge',
        basePrice: 800,
        startTime: '17:00',
        endTime: '22:00',
        daysOfWeek: ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY'],
        priority: 10,
      },
      {
        facilityId: facility.id,
        name: 'Weekend Special',
        basePrice: 1000,
        daysOfWeek: ['SATURDAY', 'SUNDAY'],
        priority: 5,
      }
    ]
  });

  // 11. Availability Block
  await prisma.availabilityBlock.deleteMany({ where: { facilityId: facility.id } });
  await prisma.availabilityBlock.create({
    data: {
      facilityId: facility.id,
      startTime: new Date('2026-08-30T10:00:00Z'),
      endTime: new Date('2026-08-30T12:00:00Z'),
      reason: 'MAINTENANCE',
      notes: 'Monthly turf cleaning',
    }
  });

  // 12. Test Bookings for Phase 56
  const customerUser = await prisma.user.upsert({
    where: { email: 'customer@playhub.com' },
    update: {},
    create: {
      email: 'customer@playhub.com',
      fullName: 'Rahul Customer',
      passwordHash: passwordHash,
      status: AccountStatus.ACTIVE,
      isEmailVerified: true,
    },
  });

  await prisma.booking.deleteMany({ where: { organizationId: partnerOrg.id } });

  // 12a. Pending Booking
  await prisma.booking.create({
    data: {
      organizationId: partnerOrg.id,
      userId: customerUser.id,
      facilityId: facility.id,
      startTime: new Date('2026-08-31T17:00:00Z'),
      endTime: new Date('2026-08-31T18:00:00Z'),
      status: BookingStatus.PENDING,
      totalPrice: 500,
      currency: 'INR',
    }
  });

  // 12b. Confirmed Booking
  await prisma.booking.create({
    data: {
      organizationId: partnerOrg.id,
      userId: customerUser.id,
      facilityId: facility.id,
      startTime: new Date('2026-08-31T19:00:00Z'),
      endTime: new Date('2026-08-31T20:00:00Z'),
      status: BookingStatus.CONFIRMED,
      totalPrice: 800,
      currency: 'INR',
    }
  });

  console.log('Seed Phase 56 completed successfully');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
