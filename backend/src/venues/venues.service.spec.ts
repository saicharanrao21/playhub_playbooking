import { Test, TestingModule } from '@nestjs/testing';
import { VenuesService } from './venues.service';
import { PrismaService } from '../prisma/prisma.service';
import { GeocodingService } from '../common/services/geocoding.service';
import { ForbiddenException, ConflictException, NotFoundException } from '@nestjs/common';
import { NearbyVenuesQueryDto } from '../discovery/dto/nearby-venues-query.dto';

describe('VenuesService (Domain Isolation)', () => {
  let service: VenuesService;
  let prisma: PrismaService;

  const mockPrisma = {
    business: { findFirst: jest.fn() },
    venue: { findUnique: jest.fn(), create: jest.fn(), findFirst: jest.fn(), findMany: jest.fn(), count: jest.fn() },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        VenuesService,
        GeocodingService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<VenuesService>(VenuesService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should throw ForbiddenException if business does not belong to organization', async () => {
    mockPrisma.business.findFirst.mockResolvedValue(null);

    await expect(service.create('org1', 'biz1', {} as any))
      .rejects.toThrow(ForbiddenException);
  });

  it('should throw ConflictException if slug is duplicated for business', async () => {
    mockPrisma.business.findFirst.mockResolvedValue({ id: 'biz1' });
    mockPrisma.venue.findUnique.mockResolvedValue({ id: 'v1' });

    await expect(service.create('org1', 'biz1', { slug: 'arena-1' } as any))
      .rejects.toThrow(ConflictException);
  });

  it('should create venue if ownership and slug are valid', async () => {
    const dto = { name: 'Arena', slug: 'arena-1', address: 'Main St', city: 'Hyd', state: 'TS', country: 'IN', postalCode: '500' };
    mockPrisma.business.findFirst.mockResolvedValue({ id: 'biz1' });
    mockPrisma.venue.findUnique.mockResolvedValue(null);
    mockPrisma.venue.create.mockResolvedValue({ id: 'v1', ...dto });

    const result = await service.create('org1', 'biz1', dto as any);
    expect(result.id).toBe('v1');
    expect(mockPrisma.venue.create).toHaveBeenCalledWith({
      data: expect.objectContaining({ businessId: 'biz1' })
    });
  });

  it('should find all venues for an organization', async () => {
    mockPrisma.venue.findMany.mockResolvedValue([{ id: 'v1' }]);
    mockPrisma.venue.count.mockResolvedValue(1);

    const result = await service.findAll('org1', { skip: 0, take: 10 });
    expect(result.items).toHaveLength(1);
    expect(result.total).toBe(1);
    expect(mockPrisma.venue.findMany).toHaveBeenCalledWith(expect.objectContaining({
       where: { business: { organizationId: 'org1' } }
    }));
  });

  it('should throw NotFoundException if venue not found in organization', async () => {
     mockPrisma.venue.findFirst.mockResolvedValue(null);
     await expect(service.findOne('org1', 'v2')).rejects.toThrow(NotFoundException);
  });

  it('should find a venue if it belongs to the organization', async () => {
     const mockVenue = { id: 'v1', businessId: 'biz1' };
     mockPrisma.venue.findFirst.mockResolvedValue(mockVenue);

     const result = await service.findOne('org1', 'v1');
     expect(result).toEqual(mockVenue);
     expect(mockPrisma.venue.findFirst).toHaveBeenCalledWith(expect.objectContaining({
        where: { id: 'v1', business: { organizationId: 'org1' } }
     }));
  });

  it('should discover active venues with filters', async () => {
    mockPrisma.venue.findMany.mockResolvedValue([{ id: 'v1' }]);
    mockPrisma.venue.count.mockResolvedValue(1);

    const result = await service.discover({ query: 'arena', skip: 0, limit: 10 });
    expect(result.items).toHaveLength(1);
    expect(mockPrisma.venue.findMany).toHaveBeenCalledWith(expect.objectContaining({
       where: expect.objectContaining({ status: 'ACTIVE' })
    }));
  });

  it('should find nearby venues within radius and compute distance', async () => {
    mockPrisma.venue.findMany.mockResolvedValue([
      { id: 'v1', name: 'Gachibowli Turf', latitude: 17.4401, longitude: 78.3489, facilities: [] },
      { id: 'v2', name: 'Far Away Turf', latitude: 18.5204, longitude: 73.8567, facilities: [] }, // Pune (~500 km away)
    ]);

    const query = Object.assign(new NearbyVenuesQueryDto(), { latitude: 17.4401, longitude: 78.3489, radius: 10 });
    const result = await service.findNearby(query);
    expect(result.items).toHaveLength(1);
    expect(result.items[0].id).toBe('v1');
    expect(result.items[0].distanceFormatted).toBeDefined();
  });
});
