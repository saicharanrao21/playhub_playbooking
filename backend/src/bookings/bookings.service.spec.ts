import { Test, TestingModule } from '@nestjs/testing';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { BookingsService } from './bookings.service';
import { PrismaService } from '../prisma/prisma.service';
import { AvailabilityService } from '../availability/availability.service';
import { PricingService } from '../availability/pricing.service';
import { ConflictException, NotFoundException, BadRequestException } from '@nestjs/common';
import { BookingStatus, VenueStatus, FacilityStatus, PaymentStatus } from '@prisma/client';
import { Events } from '../common/constants/events';
import { DateTime } from 'luxon';

describe('BookingsService (Concurrency & Logic)', () => {
  let service: BookingsService;
  let prisma: PrismaService;

  const mockPrisma = {
    facility: { findFirst: jest.fn() },
    booking: { findFirst: jest.fn(), create: jest.fn(), findUnique: jest.fn(), findMany: jest.fn(), update: jest.fn(), count: jest.fn() },
    payment: { updateMany: jest.fn() },
    $transaction: jest.fn((cb) => cb(mockPrisma)),
  };

  const mockAvailability = {
    getAvailability: jest.fn(),
  };

  const mockPricingService = {
    calculatePrice: jest.fn().mockResolvedValue({ totalPrice: 100.0, currency: 'INR', breakdown: [] }),
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
        { provide: PricingService, useValue: mockPricingService },
        { provide: EventEmitter2, useValue: mockEventEmitter },
      ],
    }).compile();

    service = module.get<BookingsService>(BookingsService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  const futureStart = DateTime.now().plus({ days: 1 }).startOf('hour').toISO();
  const futureEnd = DateTime.now().plus({ days: 1 }).startOf('hour').plus({ hours: 1 }).toISO();

  it('should create booking as PENDING and calculate price if no overlaps and available', async () => {
    const dto = { startTime: futureStart!, endTime: futureEnd! };

    mockPrisma.facility.findFirst.mockResolvedValue({
      id: 'f1',
      status: FacilityStatus.ACTIVE,
      venue: { status: VenueStatus.ACTIVE, business: { organizationId: 'org1' }, timezone: 'UTC' },
    });
    mockPrisma.booking.findFirst.mockResolvedValue(null);

    mockAvailability.getAvailability.mockResolvedValue({
      slots: [{ startTime: futureStart, endTime: futureEnd }]
    });

    mockPrisma.booking.create.mockResolvedValue({ id: 'b1', status: BookingStatus.PENDING, totalPrice: 100.0, ...dto });

    const result = await service.create('org1', 'u1', 'f1', dto);

    expect(result.id).toBe('b1');
    expect(result.status).toBe(BookingStatus.PENDING);
    expect(mockPricingService.calculatePrice).toHaveBeenCalled();
  });

  it('should throw BadRequestException if creating booking in the past', async () => {
    const pastTime = '2020-01-01T10:00:00Z';
    const dto = { startTime: pastTime, endTime: '2020-01-01T11:00:00Z' };

    await expect(service.create('org1', 'u1', 'f1', dto))
      .rejects.toThrow(BadRequestException);
  });
});
