import {
  Controller,
  Get,
  Post,
  Param,
  Query,
  Body,
  UseGuards,
  Header,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { AnalyticsService } from './analytics.service';
import { ReportsService } from './reports.service';
import { AnalyticsFilterDto } from './dto/analytics-filter.dto';
import { ExportReportDto } from './dto/export-report.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OrganizationGuard } from '../common/guards/organization.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { Permissions } from '../common/constants/permissions';
import { OrganizationContext } from '../common/decorators/organization-context.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserIdentity } from '../common/interfaces/user-identity.interface';

@ApiTags('partner-analytics')
@Controller('organizations/:organizationId/analytics')
@UseGuards(JwtAuthGuard, OrganizationGuard, PermissionsGuard)
@ApiBearerAuth()
@ApiHeader({ name: 'x-organization-id', required: true })
export class PartnerAnalyticsController {
  constructor(
    private readonly analyticsService: AnalyticsService,
    private readonly reportsService: ReportsService,
  ) {}

  @Get('dashboard')
  @RequirePermission(Permissions.ORGANIZATION_READ)
  @ApiOperation({ summary: 'Partner: Get organization analytics dashboard' })
  async getPartnerDashboardAnalytics(
    @OrganizationContext() organizationId: string,
    @Query() query: AnalyticsFilterDto,
  ) {
    return this.analyticsService.getPartnerDashboardAnalytics(organizationId, query);
  }

  @Get('peak-times')
  @RequirePermission(Permissions.ORGANIZATION_READ)
  @ApiOperation({ summary: 'Partner: Get 7x24 peak-time court booking density heatmap' })
  async getPeakTimesHeatmap(
    @OrganizationContext() organizationId: string,
    @Query() query: AnalyticsFilterDto,
  ) {
    return this.analyticsService.getPeakTimesHeatmap(organizationId, query);
  }

  @Post('exports/csv')
  @RequirePermission(Permissions.ORGANIZATION_READ)
  @Header('Content-Type', 'text/csv')
  @ApiOperation({ summary: 'Partner: Generate CSV report export' })
  async generateCsvExport(
    @OrganizationContext() organizationId: string,
    @Body() dto: ExportReportDto,
  ) {
    return this.reportsService.generateCsvExport(organizationId, dto);
  }

  @Post('reports/pdf')
  @RequirePermission(Permissions.ORGANIZATION_READ)
  @ApiOperation({ summary: 'Partner: Request asynchronous PDF performance report generation' })
  async requestPdfReportJob(
    @OrganizationContext() organizationId: string,
    @CurrentUser() user: UserIdentity,
    @Body() dto: ExportReportDto,
  ) {
    return this.reportsService.requestPdfReportJob(user.userId, organizationId, dto);
  }

  @Get('reports/:jobId')
  @RequirePermission(Permissions.ORGANIZATION_READ)
  @ApiOperation({ summary: 'Partner: Check PDF report generation status & download URL' })
  async getReportJobStatus(
    @CurrentUser() user: UserIdentity,
    @Param('jobId') jobId: string,
  ) {
    return this.reportsService.getReportJobStatus(user.userId, jobId);
  }
}
