import { Test, TestingModule } from '@nestjs/testing';
import { AdminService } from './admin.service';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../common/services/audit.service';
import { VenuesService } from '../venues/venues.service';
import { KYCStatus, BusinessStatus } from '@prisma/client';

describe('AdminService', () => {
  let service: AdminService;
  let prisma: PrismaService;

  const mockPrisma = {
    user: { count: jest.fn() },
    venue: { count: jest.fn() },
    booking: { count: jest.fn() },
    business: { count: jest.fn(), updateMany: jest.fn(), findUnique: jest.fn(), update: jest.fn() },
    organization: { count: jest.fn(), findMany: jest.fn(), findUnique: jest.fn(), update: jest.fn() },
    auditLog: { findMany: jest.fn(), count: jest.fn() },
    $transaction: jest.fn((cb) => cb(mockPrisma)),
  };

  const mockAuditService = {
    record: jest.fn(),
  };

  const mockVenuesService = {
    getVenuesMissingCoordinates: jest.fn().mockResolvedValue([]),
    batchGeocodeVenues: jest.fn().mockResolvedValue({ total: 0, updatedCount: 0 }),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AdminService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: AuditService, useValue: mockAuditService },
        { provide: VenuesService, useValue: mockVenuesService },
      ],
    }).compile();

    service = module.get<AdminService>(AdminService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should get dashboard stats', async () => {
    mockPrisma.user.count.mockResolvedValue(100);
    mockPrisma.venue.count.mockResolvedValue(10);
    mockPrisma.booking.count.mockResolvedValue(50);
    mockPrisma.business.count.mockResolvedValue(5);
    mockPrisma.organization.count.mockResolvedValue(2);

    const stats = await service.getDashboardStats();
    expect(stats.totalUsers).toBe(100);
    expect(stats.pendingKYC).toBe(2);
  });

  it('should review and approve a partner', async () => {
    const orgId = 'org-1';
    mockPrisma.organization.findUnique.mockResolvedValue({ id: orgId, kycStatus: KYCStatus.SUBMITTED });
    mockPrisma.organization.update.mockResolvedValue({ id: orgId, kycStatus: KYCStatus.APPROVED });

    await service.reviewPartner('admin-1', orgId, { kycStatus: KYCStatus.APPROVED });

    expect(mockPrisma.organization.update).toHaveBeenCalledWith(expect.objectContaining({
      where: { id: orgId },
      data: { kycStatus: KYCStatus.APPROVED },
    }));
    expect(mockPrisma.business.updateMany).toHaveBeenCalled();
    expect(mockAuditService.record).toHaveBeenCalled();
  });
});
