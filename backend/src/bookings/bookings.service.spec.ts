import { Test, TestingModule } from '@nestjs/testing';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { BookingsService } from './bookings.service';
import { PrismaService } from '../prisma/prisma.service';
import { AvailabilityService } from '../availability/availability.service';
import { ConflictException, NotFoundException } from '@nestjs/common';
import { BookingStatus } from '@prisma/client';
import { Events } from '../common/constants/events';

describe('BookingsService (Concurrency & Logic)', () => {
  let service: BookingsService;
  let prisma: PrismaService;

  const mockPrisma = {
    facility: { findFirst: jest.fn() },
    booking: { findFirst: jest.fn(), create: jest.fn(), findUnique: jest.fn(), findMany: jest.fn(), update: jest.fn() },
    $transaction: jest.fn((cb) => cb(mockPrisma)),
  };

  const mockAvailability = {
    getAvailability: jest.fn(),
  };

  const mockEventEmitter = {
    emit: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        BookingsService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: AvailabilityService, useValue: mockAvailability },
        { provide: EventEmitter2, useValue: mockEventEmitter },
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

  it('should handle 10 concurrent requests and allow only one', async () => {
    const start = '2026-08-20T10:00:00Z';
    const end = '2026-08-20T11:00:00Z';
    const dto = { startTime: start, endTime: end };

    mockPrisma.facility.findFirst.mockResolvedValue({ id: 'f1', venue: { timezone: 'UTC' } });

    // Simulate race condition where multiple requests pass the first check
    mockPrisma.booking.findFirst.mockResolvedValue(null);
    mockAvailability.getAvailability.mockResolvedValue({
      availableIntervals: [{ contains: () => true }]
    });

    // Mock create to succeed once, then fail with Prisma unique constraint/exclusion error for others
    let callCount = 0;
    mockPrisma.booking.create.mockImplementation(() => {
      callCount++;
      if (callCount === 1) return Promise.resolve({ id: 'b_first' });
      throw new Error('P2002: Unique constraint failed');
    });

    const requests = Array(10).fill(null).map(() => service.create('org1', 'u1', 'f1', dto));

    const results = await Promise.allSettled(requests);

    const fulfilled = results.filter(r => r.status === 'fulfilled');
    const rejected = results.filter(r => r.status === 'rejected');

    expect(fulfilled.length).toBe(1);
    expect(rejected.length).toBe(9);
  });

  it('should list bookings for an organization', async () => {
    mockPrisma.booking.findMany.mockResolvedValue([{ id: 'b1' }]);
    const result = await service.findAll('org1', { userId: 'u1' });
    expect(result).toHaveLength(1);
    expect(mockPrisma.booking.findMany).toHaveBeenCalledWith(expect.objectContaining({
      where: expect.objectContaining({ organizationId: 'org1', userId: 'u1' })
    }));
  });

  it('should find one booking and enforce organization isolation', async () => {
    mockPrisma.booking.findFirst.mockResolvedValue({ id: 'b1', organizationId: 'org1' });
    const result = await service.findOne('org1', 'b1');
    expect(result.id).toBe('b1');
  });

  it('should throw NotFoundException if booking not in organization', async () => {
    mockPrisma.booking.findFirst.mockResolvedValue(null);
    await expect(service.findOne('org1', 'b2')).rejects.toThrow(NotFoundException);
  });

  it('should cancel an eligible booking', async () => {
    const mockBooking = { id: 'b1', status: BookingStatus.CONFIRMED, organizationId: 'org1', userId: 'u1', facility: { name: 'F1' }, startTime: new Date() };
    mockPrisma.booking.findFirst.mockResolvedValue(mockBooking);
    mockPrisma.booking.update.mockResolvedValue({ ...mockBooking, status: BookingStatus.CANCELLED });

    const result = await service.cancel('org1', 'b1');
    expect(result.status).toBe(BookingStatus.CANCELLED);
    expect(mockEventEmitter.emit).toHaveBeenCalledWith(Events.BOOKING_CANCELLED, expect.any(Object));
  });
});
