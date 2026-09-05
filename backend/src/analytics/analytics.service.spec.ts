import { Test, TestingModule } from '@nestjs/testing';
import { AnalyticsService } from './analytics.service';
import { ReportsService } from './reports.service';
import { PrismaService } from '../prisma/prisma.service';
import { STORAGE_PROVIDER } from '../common/storage/storage-provider.interface';
import { AuditService } from '../common/services/audit.service';
import { DatePreset } from './dto/analytics-filter.dto';
import { ReportType, ExportFormat } from './dto/export-report.dto';
import { Decimal } from '@prisma/client/runtime/library';

describe('AnalyticsService & Enterprise Reporting Engine', () => {
  let analyticsService: AnalyticsService;
  let reportsService: ReportsService;

  const mockPrisma = {
    booking: {
      count: jest.fn(),
      findMany: jest.fn(),
      groupBy: jest.fn(),
    },
    payment: {
      aggregate: jest.fn(),
    },
    payout: {
      findMany: jest.fn(),
    },
    venue: {
      count: jest.fn(),
      findMany: jest.fn(),
    },
    organization: {
      count: jest.fn(),
    },
    user: {
      count: jest.fn(),
    },
    reportJob: {
      create: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
  };

  const mockStorage = {
    getPublicUrl: jest.fn().mockReturnValue('https://cdn.playhub.app/report.pdf'),
    createPresignedDownload: jest.fn().mockResolvedValue({
      downloadUrl: 'https://s3.amazonaws.com/report_download.pdf',
      expiresAt: new Date(),
    }),
  };

  const mockAuditService = {
    record: jest.fn().mockResolvedValue({}),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AnalyticsService,
        ReportsService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: STORAGE_PROVIDER, useValue: mockStorage },
        { provide: AuditService, useValue: mockAuditService },
      ],
    }).compile();

    analyticsService = module.get<AnalyticsService>(AnalyticsService);
    reportsService = module.get<ReportsService>(ReportsService);
  });

  it('should calculate partner dashboard analytics with revenue and booking metrics', async () => {
    mockPrisma.booking.count.mockResolvedValue(10);
    mockPrisma.payment.aggregate.mockResolvedValue({ _sum: { amount: new Decimal(5000) } });
    mockPrisma.venue.findMany.mockResolvedValue([{ id: 'v1' }]);
    mockPrisma.booking.groupBy.mockResolvedValue([{ userId: 'u1' }]);

    const res: any = await analyticsService.getPartnerDashboardAnalytics('org-101', {
      preset: DatePreset.LAST_30_DAYS,
    });

    expect(res.revenue.grossRevenue).toBe(5000);
    expect(res.bookings.totalBookings).toBe(10);
    expect(res.customers.uniqueCustomers).toBe(1);
  });

  it('should generate peak-time 7x24 booking density heatmap', async () => {
    mockPrisma.booking.findMany.mockResolvedValue([
      { startTime: new Date('2026-09-06T18:00:00Z'), totalPrice: new Decimal(1000) },
    ]);

    const heatmap = await analyticsService.getPeakTimesHeatmap('org-101', { preset: DatePreset.LAST_7_DAYS });

    expect(heatmap.heatmapGrid).toHaveLength(7);
    expect(heatmap.heatmapGrid[0]).toHaveLength(24);
  });

  it('should generate RFC 4180-compliant CSV report export', async () => {
    mockPrisma.booking.findMany.mockResolvedValue([
      {
        id: 'book-101',
        status: 'CONFIRMED',
        totalPrice: new Decimal(800),
        createdAt: new Date('2026-09-01T10:00:00Z'),
        user: { fullName: 'Aarav', email: 'aarav@playhub.com' },
        facility: { name: 'Court 1', venue: { name: 'Gachibowli Arena' } },
      },
    ]);

    const csv = await reportsService.generateCsvExport('org-101', {
      reportType: ReportType.BOOKINGS,
      format: ExportFormat.CSV,
      preset: DatePreset.LAST_30_DAYS,
    });

    expect(csv).toContain('Booking ID,Customer Name');
    expect(csv).toContain('book-101');
    expect(csv).toContain('"Aarav"');
  });

  it('should process PDF report job and attach presigned download URL', async () => {
    mockPrisma.reportJob.findUnique.mockResolvedValue({
      id: 'job-101',
      organizationId: 'org-101',
      reportType: 'PARTNER_MONTHLY_PERFORMANCE',
      status: 'QUEUED',
    });

    mockPrisma.reportJob.update.mockResolvedValue({ id: 'job-101', status: 'READY' });

    await reportsService.processPdfReportJob('job-101');

    expect(mockStorage.createPresignedDownload).toHaveBeenCalled();
    expect(mockPrisma.reportJob.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'job-101' },
        data: expect.objectContaining({ status: 'READY' }),
      }),
    );
  });
});
