import { Test, TestingModule } from '@nestjs/testing';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { BookingsService } from './bookings.service';
import { PrismaService } from '../prisma/prisma.service';
import { AvailabilityService } from '../availability/availability.service';
import { ConflictException, NotFoundException, BadRequestException } from '@nestjs/common';
import { BookingStatus, VenueStatus, FacilityStatus } from '@prisma/client';
import { Events } from '../common/constants/events';
import { DateTime } from 'luxon';

describe('BookingsService (Concurrency & Logic)', () => {
  let service: BookingsService;
  let prisma: PrismaService;

  const mockPrisma = {
    facility: { findFirst: jest.fn() },
    booking: { findFirst: jest.fn(), create: jest.fn(), findUnique: jest.fn(), findMany: jest.fn(), update: jest.fn() },
    payment: { updateMany: jest.fn() },
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

  const futureStart = DateTime.now().plus({ days: 1 }).startOf('hour').toISO();
  const futureEnd = DateTime.now().plus({ days: 1 }).startOf('hour').plus({ hours: 1 }).toISO();

  it('should throw ConflictException if overlapping booking exists', async () => {
    mockPrisma.facility.findFirst.mockResolvedValue({
      id: 'f1',
      status: FacilityStatus.ACTIVE,
      venue: { status: VenueStatus.ACTIVE, timezone: 'UTC' },
      pricingRules: [{ basePrice: 100, currency: 'INR' }]
    });
    mockPrisma.booking.findFirst.mockResolvedValue({ id: 'existing' });

    const dto = { startTime: futureStart!, endTime: futureEnd! };

    await expect(service.create('org1', 'u1', 'f1', dto))
      .rejects.toThrow(ConflictException);

    expect(mockPrisma.booking.findFirst).toHaveBeenCalled();
  });

  it('should create booking as PENDING and calculate price if no overlaps and available', async () => {
    const dto = { startTime: futureStart!, endTime: futureEnd! };

    mockPrisma.facility.findFirst.mockResolvedValue({
      id: 'f1',
      status: FacilityStatus.ACTIVE,
      venue: { status: VenueStatus.ACTIVE, business: { organizationId: 'org1' }, timezone: 'UTC' },
      pricingRules: [{ basePrice: 100.00, currency: 'INR' }]
    });
    mockPrisma.booking.findFirst.mockResolvedValue(null);

    mockAvailability.getAvailability.mockResolvedValue({
      availableIntervals: [{ contains: () => true }]
    });

    mockPrisma.booking.create.mockResolvedValue({ id: 'b1', status: BookingStatus.PENDING, totalPrice: 100.00, ...dto });

    const result = await service.create('org1', 'u1', 'f1', dto);

    expect(result.id).toBe('b1');
    expect(result.status).toBe(BookingStatus.PENDING);
    expect(mockPrisma.booking.create).toHaveBeenCalledWith(expect.objectContaining({
      data: expect.objectContaining({
        status: BookingStatus.PENDING,
        totalPrice: 100.00,
        currency: 'INR'
      })
    }));
  });

  it('should throw BadRequestException if creating booking in the past', async () => {
    const pastTime = '2020-01-01T10:00:00Z';
    const dto = { startTime: pastTime, endTime: '2020-01-01T11:00:00Z' };

    await expect(service.create('org1', 'u1', 'f1', dto))
      .rejects.toThrow(BadRequestException);
  });

  it('should throw NotFoundException if facility is INACTIVE', async () => {
    const dto = { startTime: futureStart!, endTime: futureEnd! };
    mockPrisma.facility.findFirst.mockResolvedValue(null);

    await expect(service.create('org1', 'u1', 'f1', dto))
      .rejects.toThrow(NotFoundException);
  });

  it('should handle 10 concurrent requests and allow only one', async () => {
    const dto = { startTime: futureStart!, endTime: futureEnd! };

    mockPrisma.facility.findFirst.mockResolvedValue({
      id: 'f1',
      status: FacilityStatus.ACTIVE,
      venue: { status: VenueStatus.ACTIVE, timezone: 'UTC' },
      pricingRules: [{ basePrice: 100, currency: 'INR' }]
    });
    mockPrisma.booking.findFirst.mockResolvedValue(null);
    mockAvailability.getAvailability.mockResolvedValue({
      availableIntervals: [{ contains: () => true }]
    });

    let callCount = 0;
    mockPrisma.booking.create.mockImplementation(() => {
      callCount++;
      if (callCount === 1) return Promise.resolve({ id: 'b_first' });
      throw new Error('P2002: Unique constraint failed');
    });

    const requests = Array(10).fill(null).map(() => service.create('org1', 'u1', 'f1', dto));
    const results = await Promise.allSettled(requests);

    expect(results.filter(r => r.status === 'fulfilled').length).toBe(1);
    expect(results.filter(r => r.status === 'rejected').length).toBe(9);
  });

  it('should find one booking for owner', async () => {
    mockPrisma.booking.findFirst.mockResolvedValue({ id: 'b1', organizationId: 'org1', userId: 'u1' });
    const result = await service.findOne('org1', 'b1', 'u1');
    expect(result.id).toBe('b1');
    expect(mockPrisma.booking.findFirst).toHaveBeenCalledWith(expect.objectContaining({
      where: expect.objectContaining({ id: 'b1', organizationId: 'org1', userId: 'u1' })
    }));
  });

  it('should cancel an eligible booking for owner', async () => {
    const mockBooking = {
      id: 'b1',
      status: BookingStatus.CONFIRMED,
      organizationId: 'org1',
      userId: 'u1',
      facility: {
        name: 'F1',
        status: FacilityStatus.ACTIVE,
        venue: { status: VenueStatus.ACTIVE }
      },
      startTime: new Date()
    };
    mockPrisma.booking.findFirst.mockResolvedValue(mockBooking);
    mockPrisma.booking.update.mockResolvedValue({ ...mockBooking, status: BookingStatus.CANCELLED });

    const result = await service.cancel('org1', 'b1', 'Change of plans', 'u1');
    expect(result.status).toBe(BookingStatus.CANCELLED);
    expect(mockPrisma.booking.update).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: 'b1' }
    }));
  });

  it('should throw BadRequestException for invalid status transition in cancel', async () => {
    mockPrisma.booking.findFirst.mockResolvedValue({
      id: 'b1',
      status: BookingStatus.COMPLETED,
      organizationId: 'org1',
      facility: { status: FacilityStatus.ACTIVE, venue: { status: VenueStatus.ACTIVE } }
    });
    await expect(service.cancel('org1', 'b1', undefined, 'u1')).rejects.toThrow(BadRequestException);
  });

  it('should reschedule a booking for owner', async () => {
    const mockBooking = {
      id: 'b1',
      userId: 'u1',
      status: BookingStatus.CONFIRMED,
      facilityId: 'f1',
      facility: {
        status: FacilityStatus.ACTIVE,
        venue: { status: VenueStatus.ACTIVE, timezone: 'UTC' },
        name: 'F1'
      },
      startTime: new Date(futureStart!),
      endTime: new Date(futureEnd!),
    };

    const nextDayStart = DateTime.fromISO(futureStart!).plus({ days: 1 }).toISO();
    const nextDayEnd = DateTime.fromISO(futureEnd!).plus({ days: 1 }).toISO();

    mockPrisma.booking.findFirst
      .mockResolvedValueOnce(mockBooking) // findOne
      .mockResolvedValueOnce(null); // overlap check

    mockAvailability.getAvailability.mockResolvedValue({
      availableIntervals: [{ contains: () => true }]
    });
    mockPrisma.booking.update.mockResolvedValue({ ...mockBooking, startTime: new Date(nextDayStart!) });

    const dto = { newStartTime: nextDayStart!, newEndTime: nextDayEnd! };
    const result = await service.reschedule('org1', 'b1', dto, 'u1');

    expect(result.id).toBe('b1');
    expect(mockPrisma.booking.findFirst).toHaveBeenCalledWith(expect.objectContaining({
      where: expect.objectContaining({ id: 'b1', organizationId: 'org1', userId: 'u1' })
    }));
  });

  it('should throw BadRequestException when rescheduling to the past', async () => {
    const dto = { newStartTime: '2020-01-01T10:00:00Z', newEndTime: '2020-01-01T11:00:00Z' };
    await expect(service.reschedule('org1', 'b1', dto, 'u1')).rejects.toThrow(BadRequestException);
  });

  it('should throw BadRequestException if facility or venue is INACTIVE during reschedule', async () => {
    const mockBooking = {
      id: 'b1',
      userId: 'u1',
      status: BookingStatus.CONFIRMED,
      facilityId: 'f1',
      facility: {
        status: FacilityStatus.INACTIVE,
        venue: { status: VenueStatus.ACTIVE, timezone: 'UTC' },
        name: 'F1'
      },
      startTime: new Date(futureStart!),
      endTime: new Date(futureEnd!),
    };

    mockPrisma.booking.findFirst.mockResolvedValue(mockBooking);

    const dto = { newStartTime: futureStart!, newEndTime: futureEnd! };
    await expect(service.reschedule('org1', 'b1', dto, 'u1')).rejects.toThrow(BadRequestException);
  });
});
