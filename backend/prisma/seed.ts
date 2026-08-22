import { PrismaClient, VenueStatus, FacilityStatus } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  // Cities
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

  // Categories
  const sports = await prisma.category.upsert({
    where: { slug: 'sports' },
    update: {},
    create: { name: 'Sports', slug: 'sports', icon: 'sports_soccer' },
  });

  // Activities
  const football = await prisma.activity.upsert({
    where: { categoryId_slug: { categoryId: sports.id, slug: 'football' } },
    update: {},
    create: { name: 'Football', slug: 'football', categoryId: sports.id },
  });

  const cricket = await prisma.activity.upsert({
    where: { categoryId_slug: { categoryId: sports.id, slug: 'cricket' } },
    update: {},
    create: { name: 'Cricket', slug: 'cricket', categoryId: sports.id },
  });

  console.log('Seed completed successfully');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
