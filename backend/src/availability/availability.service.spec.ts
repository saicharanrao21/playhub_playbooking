import { Test, TestingModule } from '@nestjs/testing';
import { AvailabilityService } from './availability.service';
import { PrismaService } from '../prisma/prisma.service';
import { PricingService } from './pricing.service';

describe('AvailabilityService', () => {
  let service: AvailabilityService;
  let prisma: PrismaService;

  const mockPrisma = {
    facility: { findFirst: jest.fn() },
    availabilityBlock: { findMany: jest.fn() },
    booking: { findMany: jest.fn() },
  };

  const mockPricingService = {
    calculatePrice: jest.fn().mockResolvedValue({ totalPrice: 1000, currency: 'INR', breakdown: [] }),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AvailabilityService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: PricingService, useValue: mockPricingService },
      ],
    }).compile();

    service = module.get<AvailabilityService>(AvailabilityService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should return correct slots for simple operating hours', async () => {
    const mockFacility = {
      id: 'f1',
      defaultSlotDuration: 60,
      venue: {
        timezone: 'UTC',
        operatingHours: [
          { dayOfWeek: 'THURSDAY', openingTime: '09:00', closingTime: '12:00', isClosed: false },
        ],
      },
    };

    mockPrisma.facility.findFirst.mockResolvedValue(mockFacility);
    mockPrisma.availabilityBlock.findMany.mockResolvedValue([]);
    mockPrisma.booking.findMany.mockResolvedValue([]);

    const result = await service.getAvailability('org1', 'f1', '2026-08-20', 60);

    expect(result.slots.length).toBe(3);
    expect(result.slots[0].startTime).toContain('09:00');
    expect(result.slots[2].endTime).toContain('12:00');
  });
});
