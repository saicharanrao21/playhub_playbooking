import { Test, TestingModule } from '@nestjs/testing';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { BookingsService } from './bookings.service';
import { PrismaService } from '../prisma/prisma.service';
import { AvailabilityService } from '../availability/availability.service';
import { PricingService } from '../availability/pricing.service';
import { QrService } from './qr.service';
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

  const mockQrService = {
    generateBookingToken: jest.fn().mockResolvedValue('mock-token'),
    verifyBookingToken: jest.fn().mockResolvedValue({ bookingId: 'b1', organizationId: 'org1' }),
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
        { provide: QrService, useValue: mockQrService },
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

  it('should accept a pending booking', async () => {
    mockPrisma.booking.findFirst.mockResolvedValue({ id: 'b1', status: BookingStatus.PENDING, organizationId: 'org1' });
    mockPrisma.booking.update.mockResolvedValue({ id: 'b1', status: BookingStatus.CONFIRMED, facility: { name: 'F1' }, organizationId: 'org1' });

    const result = await service.accept('org1', 'b1');

    expect(result.status).toBe(BookingStatus.CONFIRMED);
    expect(mockEventEmitter.emit).toHaveBeenCalledWith(Events.BOOKING_ACCEPTED, expect.anything());
  });

  it('should reject a pending booking', async () => {
    mockPrisma.booking.findFirst.mockResolvedValue({ id: 'b1', status: BookingStatus.PENDING, organizationId: 'org1' });
    mockPrisma.booking.update.mockResolvedValue({ id: 'b1', status: BookingStatus.REJECTED, facility: { name: 'F1' }, organizationId: 'org1' });

    const result = await service.reject('org1', 'b1', 'Busy day');

    expect(result.status).toBe(BookingStatus.REJECTED);
    expect(mockEventEmitter.emit).toHaveBeenCalledWith(Events.BOOKING_REJECTED, expect.anything());
  });

  it('should check in a confirmed booking with valid QR', async () => {
    mockQrService.verifyBookingToken.mockResolvedValue({ bookingId: 'b1', organizationId: 'org1' });
    mockPrisma.booking.findFirst.mockResolvedValue({
      id: 'b1',
      status: BookingStatus.CONFIRMED,
      organizationId: 'org1',
      userId: 'u1',
      facilityId: 'f1'
    });
    mockPrisma.booking.update.mockResolvedValue({
      id: 'b1',
      status: BookingStatus.CHECKED_IN,
      facility: { name: 'F1', venueId: 'v1' },
      organizationId: 'org1',
      userId: 'u1'
    });
    mockPrisma.checkIn = { create: jest.fn().mockResolvedValue({}) };

    const result = await service.checkIn('org1', 'staff1', 'valid-token');

    expect((result as any).status).toBe(BookingStatus.CHECKED_IN);
    expect(mockPrisma.checkIn.create).toHaveBeenCalled();
  });
});
