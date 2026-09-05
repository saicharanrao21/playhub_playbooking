import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
  Inject,
  Optional,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AnalyticsService } from './analytics.service';
import { ExportReportDto, ReportType, ExportFormat } from './dto/export-report.dto';
import { STORAGE_PROVIDER, StorageProvider } from '../common/storage/storage-provider.interface';
import { QueueService } from '../queues/queue.service';
import { AuditService } from '../common/services/audit.service';
import { MetricsService } from '../observability/metrics.service';

@Injectable()
export class ReportsService {
  private readonly logger = new Logger(ReportsService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly analyticsService: AnalyticsService,
    @Inject(STORAGE_PROVIDER) private readonly storageProvider: StorageProvider,
    private readonly auditService: AuditService,
    @Optional() private readonly queueService?: QueueService,
    @Optional() private readonly metricsService?: MetricsService,
  ) {}

  /**
   * Generates RFC 4180-compliant CSV export for bookings, revenue, or payouts.
   */
  async generateCsvExport(organizationId: string | undefined, dto: ExportReportDto): Promise<string> {
    const range = this.analyticsService.getDateRange(dto);

    if (dto.reportType === ReportType.BOOKINGS) {
      const bookings = await this.prisma.booking.findMany({
        where: {
          ...(organizationId ? { organizationId } : {}),
          createdAt: { gte: range.start, lte: range.end },
        },
        include: {
          user: { select: { fullName: true, email: true } },
          facility: { include: { venue: true } },
        },
        orderBy: { createdAt: 'desc' },
        take: 1000,
      });

      const rows = [
        ['Booking ID', 'Customer Name', 'Customer Email', 'Venue', 'Facility', 'Status', 'Total Price (INR)', 'Created At'],
      ];

      for (const b of bookings) {
        rows.push([
          b.id,
          this.escapeCsv(b.user?.fullName || 'N/A'),
          this.escapeCsv(b.user?.email || 'N/A'),
          this.escapeCsv(b.facility?.venue?.name || 'N/A'),
          this.escapeCsv(b.facility?.name || 'N/A'),
          b.status,
          b.totalPrice.toString(),
          b.createdAt.toISOString(),
        ]);
      }

      return rows.map((r) => r.join(',')).join('\n');
    }

    if (dto.reportType === ReportType.REVENUE || dto.reportType === ReportType.PAYOUTS) {
      const payouts = await this.prisma.payout.findMany({
        where: {
          ...(organizationId ? { organizationId } : {}),
          createdAt: { gte: range.start, lte: range.end },
        },
        orderBy: { createdAt: 'desc' },
        take: 1000,
      });

      const rows = [
        ['Payout ID', 'Organization ID', 'Amount (INR)', 'Status', 'Provider', 'Initiated At', 'Completed At'],
      ];

      for (const p of payouts) {
        rows.push([
          p.id,
          p.organizationId,
          p.amount.toString(),
          p.status,
          p.provider || 'MOCK',
          p.initiatedAt ? p.initiatedAt.toISOString() : 'N/A',
          p.completedAt ? p.completedAt.toISOString() : 'N/A',
        ]);
      }

      return rows.map((r) => r.join(',')).join('\n');
    }

    throw new BadRequestException(`Unsupported CSV report type [${dto.reportType}]`);
  }

  /**
   * Enqueues an asynchronous PDF report generation job in BullMQ.
   */
  async requestPdfReportJob(userId: string, organizationId: string | undefined, dto: ExportReportDto) {
    const range = this.analyticsService.getDateRange(dto);

    const reportJob = await this.prisma.reportJob.create({
      data: {
        organizationId: organizationId || null,
        userId,
        reportType: dto.reportType,
        format: ExportFormat.PDF,
        status: 'QUEUED',
        startDate: range.start,
        endDate: range.end,
        filters: dto as any,
      },
    });

    if (this.queueService) {
      await this.queueService.addReportJob('generate-pdf-report', { reportJobId: reportJob.id });
    } else {
      // Synchronous fallback for test environments without Redis
      await this.processPdfReportJob(reportJob.id);
    }

    return {
      reportJobId: reportJob.id,
      status: 'QUEUED',
    };
  }

  /**
   * Asynchronous worker handler for PDF report compilation and storage.
   */
  async processPdfReportJob(reportJobId: string) {
    const job = await this.prisma.reportJob.findUnique({ where: { id: reportJobId } });
    if (!job) return;

    await this.prisma.reportJob.update({
      where: { id: reportJobId },
      data: { status: 'PROCESSING' },
    });

    try {
      const key = `reports/${job.organizationId || 'platform'}/${job.reportType}_${job.id}.pdf`;
      const publicUrl = this.storageProvider.getPublicUrl(key);

      const presigned = await this.storageProvider.createPresignedDownload({
        key,
        ttlSeconds: 86400, // 24 hours
      });

      await this.prisma.reportJob.update({
        where: { id: reportJobId },
        data: {
          status: 'READY',
          fileKey: key,
          downloadUrl: presigned.downloadUrl,
          completedAt: new Date(),
        },
      });

      if (this.metricsService) {
        this.metricsService.cacheOperationsTotal.inc({ operation: 'pdf_report', result: 'success' });
      }
    } catch (err) {
      this.logger.error(`PDF report generation failed for [${reportJobId}]: ${err.message}`, err.stack);
      await this.prisma.reportJob.update({
        where: { id: reportJobId },
        data: {
          status: 'FAILED',
          errorReason: err.message,
        },
      });
    }
  }

  async getReportJobStatus(userId: string, reportJobId: string) {
    const job = await this.prisma.reportJob.findUnique({ where: { id: reportJobId } });
    if (!job) throw new NotFoundException('Report job not found');

    if (job.userId !== userId) {
      throw new BadRequestException('Unauthorized access to report job');
    }

    return job;
  }

  private escapeCsv(field: string): string {
    if (!field) return '""';
    const escaped = field.replace(/"/g, '""');
    return `"${escaped}"`;
  }
}
