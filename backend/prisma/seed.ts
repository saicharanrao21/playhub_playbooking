import { PrismaClient, AccountStatus, BusinessStatus, VenueStatus, FacilityStatus, OrganizationStatus, KYCStatus } from '@prisma/client';
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

  await prisma.activity.upsert({
    where: { categoryId_slug: { categoryId: sports.id, slug: 'cricket' } },
    update: {},
    create: { name: 'Cricket', slug: 'cricket', categoryId: sports.id },
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
      panNumber: 'ABCDE1234F',
      gstNumber: '36ABCDE1234F1Z5',
      accountHolderName: 'Skyline Sports Ventures',
      accountNumber: '98765432101234',
      ifscCode: 'HDFC0001234',
      bankName: 'HDFC Bank',
    },
  });

  // 6. Partner Membership (Role: BUSINESS_OWNER)
  let partnerRole = await prisma.role.findUnique({ where: { name: 'BUSINESS_OWNER' } });
  if (!partnerRole) {
    partnerRole = await prisma.role.create({
      data: { name: 'BUSINESS_OWNER', description: 'Business Owner & Partner Administrator' },
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
  const partnerBusiness = await prisma.business.create({
    data: {
      organizationId: partnerOrg.id,
      legalName: 'Skyline Sports Ventures Pvt Ltd',
      displayName: 'Skyline Arena',
      status: BusinessStatus.ACTIVE,
    },
  });

  // 8. Partner Venues (Multi-Venue)
  const venue1 = await prisma.venue.create({
    data: {
      businessId: partnerBusiness.id,
      cityId: hyd.id,
      name: 'Skyline Gachibowli',
      slug: 'skyline-gachibowli',
      address: 'Plot 42, Hitech City Main Road',
      city: 'Hyderabad',
      state: 'Telangana',
      country: 'India',
      postalCode: '500081',
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

  await prisma.venue.create({
    data: {
      businessId: partnerBusiness.id,
      cityId: blr.id,
      name: 'Skyline Whitefield',
      slug: 'skyline-whitefield',
      address: 'ITPL Main Road',
      city: 'Bangalore',
      state: 'Karnataka',
      country: 'India',
      postalCode: '560066',
      status: VenueStatus.ACTIVE,
    },
  });

  // 9. Facilities for Venue 1
  const fac1 = await prisma.facility.create({
    data: {
      venueId: venue1.id,
      categoryId: sports.id,
      activityId: football.id,
      name: 'Main Football Turf',
      capacity: 10,
      status: FacilityStatus.ACTIVE,
    },
  });

  await prisma.pricingRule.create({
    data: {
      facilityId: fac1.id,
      name: 'Standard Hourly Rate',
      basePrice: 1200,
      currency: 'INR',
    },
  });

  console.log('Seed completed successfully with partner data');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
