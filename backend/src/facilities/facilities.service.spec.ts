import { Test, TestingModule } from '@nestjs/testing';
import { FacilitiesService } from './facilities.service';
import { PrismaService } from '../prisma/prisma.service';
import { NotFoundException, ForbiddenException } from '@nestjs/common';

describe('FacilitiesService (Domain Isolation)', () => {
  let service: FacilitiesService;
  let prisma: PrismaService;

  const mockPrisma = {
    venue: { findFirst: jest.fn() },
    facility: { create: jest.fn(), findMany: jest.fn(), findFirst: jest.fn(), count: jest.fn(), update: jest.fn() },
    availabilityBlock: { create: jest.fn(), delete: jest.fn() },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        FacilitiesService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<FacilitiesService>(FacilitiesService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should throw ForbiddenException if venue does not belong to organization during creation', async () => {
    mockPrisma.venue.findFirst.mockResolvedValue(null);
    await expect(service.create('org1', 'v1', {} as any)).rejects.toThrow(ForbiddenException);
  });

  it('should find a facility and enforce organization isolation', async () => {
    mockPrisma.facility.findFirst.mockResolvedValue({ id: 'f1' });
    const result = await service.findOne('org1', 'f1');
    expect(result.id).toBe('f1');
    expect(mockPrisma.facility.findFirst).toHaveBeenCalledWith(expect.objectContaining({
       where: { id: 'f1', venue: { business: { organizationId: 'org1' } } }
    }));
  });

  it('should throw NotFoundException if facility not in organization context', async () => {
    mockPrisma.facility.findFirst.mockResolvedValue(null);
    await expect(service.findOne('org1', 'f2')).rejects.toThrow(NotFoundException);
  });
});
