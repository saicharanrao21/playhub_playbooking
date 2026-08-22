import { Test, TestingModule } from '@nestjs/testing';
import { CitiesService } from './cities.service';
import { PrismaService } from '../prisma/prisma.service';
import { ConflictException, NotFoundException } from '@nestjs/common';

describe('CitiesService', () => {
  let service: CitiesService;
  let prisma: PrismaService;

  const mockPrisma = {
    city: {
      findFirst: jest.fn(),
      findMany: jest.fn(),
      findUnique: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CitiesService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<CitiesService>(CitiesService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should create a city', async () => {
    const dto = { name: 'Hyderabad', slug: 'hyderabad' };
    mockPrisma.city.findFirst.mockResolvedValue(null);
    mockPrisma.city.create.mockResolvedValue({ id: 'c1', ...dto });

    const result = await service.create(dto);
    expect(result.id).toBe('c1');
    expect(mockPrisma.city.create).toHaveBeenCalled();
  });

  it('should throw ConflictException if city exists', async () => {
    mockPrisma.city.findFirst.mockResolvedValue({ id: 'existing' });
    await expect(service.create({ name: 'Hyd', slug: 'hyd' }))
      .rejects.toThrow(ConflictException);
  });

  it('should return all active cities', async () => {
    mockPrisma.city.findMany.mockResolvedValue([{ id: 'c1', isActive: true }]);
    const result = await service.findAll();
    expect(result).toHaveLength(1);
    expect(mockPrisma.city.findMany).toHaveBeenCalledWith(expect.objectContaining({
      where: { isActive: true }
    }));
  });
});
