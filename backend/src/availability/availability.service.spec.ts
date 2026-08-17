import { Test, TestingModule } from '@nestjs/testing';
import { AvailabilityService } from './availability.service';
import { PrismaService } from '../prisma/prisma.service';

describe('AvailabilityService', () => {
  let service: AvailabilityService;
  let prisma: PrismaService;

  const mockPrisma = {
    facility: { findFirst: jest.fn() },
    availabilityBlock: { findMany: jest.fn() },
    booking: { findMany: jest.fn() },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AvailabilityService,
        { provide: PrismaService, useValue: mockPrisma },
      ],
    }).compile();

    service = module.get<AvailabilityService>(AvailabilityService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should return correct slots for simple operating hours', async () => {
    const mockFacility = {
      id: 'f1',
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
    expect(result.slots[0].start.toISO()).toContain('09:00');
    expect(result.slots[2].end.toISO()).toContain('12:00');
  });

  it('should account for facility blocks', async () => {
    const mockFacility = {
      id: 'f1',
      venue: {
        timezone: 'UTC',
        operatingHours: [
          { dayOfWeek: 'THURSDAY', openingTime: '09:00', closingTime: '12:00', isClosed: false },
        ],
      },
    };

    mockPrisma.facility.findFirst.mockResolvedValue(mockFacility);
    // Block from 10:00 to 11:00
    mockPrisma.availabilityBlock.findMany.mockResolvedValue([
      { startTime: new Date('2026-08-20T10:00:00Z'), endTime: new Date('2026-08-20T11:00:00Z') },
    ]);
    mockPrisma.booking.findMany.mockResolvedValue([]);

    const result = await service.getAvailability('org1', 'f1', '2026-08-20', 60);

    expect(result.slots.length).toBe(2);
    expect(result.slots[0].start.toISO()).toContain('09:00');
    expect(result.slots[1].start.toISO()).toContain('11:00');
  });
});
