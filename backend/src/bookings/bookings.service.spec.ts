import { Test, TestingModule } from '@nestjs/testing';
import { BookingsService } from './bookings.service';
import { PrismaService } from '../prisma/prisma.service';
import { AvailabilityService } from '../availability/availability.service';
import { ConflictException } from '@nestjs/common';
import { BookingStatus } from '@prisma/client';

describe('BookingsService (Concurrency & Logic)', () => {
  let service: BookingsService;
  let prisma: PrismaService;

  const mockPrisma = {
    facility: { findFirst: jest.fn() },
    booking: { findFirst: jest.fn(), create: jest.fn() },
    $transaction: jest.fn((cb) => cb(mockPrisma)),
  };

  const mockAvailability = {
    getAvailability: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        BookingsService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: AvailabilityService, useValue: mockAvailability },
      ],
    }).compile();

    service = module.get<BookingsService>(BookingsService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should throw ConflictException if overlapping booking exists', async () => {
    mockPrisma.facility.findFirst.mockResolvedValue({ id: 'f1', venue: { timezone: 'UTC' } });
    mockPrisma.booking.findFirst.mockResolvedValue({ id: 'existing' });

    const dto = { startTime: '2026-08-20T10:00:00Z', endTime: '2026-08-20T11:00:00Z' };

    await expect(service.create('org1', 'u1', 'f1', dto))
      .rejects.toThrow(ConflictException);

    expect(mockPrisma.booking.findFirst).toHaveBeenCalled();
  });

  it('should create booking if no overlaps and available', async () => {
    const start = '2026-08-20T10:00:00Z';
    const end = '2026-08-20T11:00:00Z';
    const dto = { startTime: start, endTime: end };

    mockPrisma.facility.findFirst.mockResolvedValue({ id: 'f1', venue: { timezone: 'UTC' } });
    mockPrisma.booking.findFirst.mockResolvedValue(null);

    // Mock availability engine result
    mockAvailability.getAvailability.mockResolvedValue({
      availableIntervals: [
        { contains: () => true } // Simplified for test
      ]
    });

    mockPrisma.booking.create.mockResolvedValue({ id: 'b1', ...dto });

    const result = await service.create('org1', 'u1', 'f1', dto);

    expect(result.id).toBe('b1');
    expect(mockPrisma.booking.create).toHaveBeenCalled();
  });
});
