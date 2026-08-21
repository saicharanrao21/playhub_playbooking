import { Test, TestingModule } from '@nestjs/testing';
import { BusinessesService } from './businesses.service';
import { PrismaService } from '../prisma/prisma.service';
import { NotFoundException } from '@nestjs/common';

describe('BusinessesService (Domain Isolation)', () => {
  let service: BusinessesService;
  let prisma: PrismaService;

  const mockPrisma = {
    business: { findFirst: jest.fn(), findMany: jest.fn(), count: jest.fn(), create: jest.fn(), update: jest.fn() },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        BusinessesService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<BusinessesService>(BusinessesService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should find all businesses for an organization', async () => {
    mockPrisma.business.findMany.mockResolvedValue([{ id: 'b1' }]);
    mockPrisma.business.count.mockResolvedValue(1);

    const result = await service.findAll('org1', { skip: 0, take: 10 });
    expect(result.items).toHaveLength(1);
    expect(result.total).toBe(1);
    expect(mockPrisma.business.findMany).toHaveBeenCalledWith(expect.objectContaining({
      where: { organizationId: 'org1' }
    }));
  });

  it('should throw NotFoundException if business not in organization', async () => {
    mockPrisma.business.findFirst.mockResolvedValue(null);
    await expect(service.findOne('org1', 'b2')).rejects.toThrow(NotFoundException);
  });

  it('should update business and enforce organization check', async () => {
    mockPrisma.business.findFirst.mockResolvedValue({ id: 'b1', organizationId: 'org1' });
    mockPrisma.business.update.mockResolvedValue({ id: 'b1', displayName: 'New Name' });

    const result = await service.update('org1', 'b1', { displayName: 'New Name' });
    expect(result.displayName).toBe('New Name');
    expect(mockPrisma.business.findFirst).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'b1', organizationId: 'org1' }
    }));
  });
});
