import { Test, TestingModule } from '@nestjs/testing';
import { MembershipsService } from './memberships.service';
import { PrismaService } from '../prisma/prisma.service';
import { NotFoundException } from '@nestjs/common';
import { Decimal } from '@prisma/client/runtime/library';

describe('MembershipsService', () => {
  let service: MembershipsService;

  const mockPrisma = {
    membershipPlan: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
    },
    customerMembership: {
      findFirst: jest.fn(),
      create: jest.fn(),
    },
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MembershipsService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<MembershipsService>(MembershipsService);
  });

  it('should purchase and activate customer membership plan', async () => {
    mockPrisma.membershipPlan.findUnique.mockResolvedValue({
      id: 'plan-101',
      name: 'Gold Member',
      status: 'ACTIVE',
      price: new Decimal(999),
      currency: 'INR',
      duration: 1,
      durationUnit: 'MONTHS',
    });

    mockPrisma.customerMembership.create.mockResolvedValue({
      id: 'm-101',
      userId: 'user-101',
      status: 'ACTIVE',
      amountPaid: new Decimal(999),
    });

    const result = await service.purchaseMembership('user-101', 'plan-101');
    expect(result.status).toBe('ACTIVE');
    expect(mockPrisma.customerMembership.create).toHaveBeenCalled();
  });

  it('should throw NotFoundException for invalid or inactive plan', async () => {
    mockPrisma.membershipPlan.findUnique.mockResolvedValue(null);

    await expect(service.purchaseMembership('user-101', 'bad-plan')).rejects.toThrow(NotFoundException);
  });
});
