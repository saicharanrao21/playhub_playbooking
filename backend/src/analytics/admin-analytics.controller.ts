import {
  Controller,
  Get,
  Post,
  Query,
  Body,
  UseGuards,
  Header,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AnalyticsService } from './analytics.service';
import { ReportsService } from './reports.service';
import { AnalyticsFilterDto } from './dto/analytics-filter.dto';
import { ExportReportDto } from './dto/export-report.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PlatformAdminGuard } from '../common/guards/platform-admin.guard';

@ApiTags('admin-analytics')
@Controller('admin/analytics')
@UseGuards(JwtAuthGuard, PlatformAdminGuard)
@ApiBearerAuth()
export class AdminAnalyticsController {
  constructor(
    private readonly analyticsService: AnalyticsService,
    private readonly reportsService: ReportsService,
  ) {}

  @Get('overview')
  @ApiOperation({ summary: 'Admin: Platform-wide overview & growth analytics' })
  async getAdminPlatformAnalytics(@Query() query: AnalyticsFilterDto) {
    return this.analyticsService.getAdminPlatformAnalytics(query);
  }

  @Post('exports/csv')
  @Header('Content-Type', 'text/csv')
  @ApiOperation({ summary: 'Admin: Generate platform-wide CSV report export' })
  async generatePlatformCsvExport(@Body() dto: ExportReportDto) {
    return this.reportsService.generateCsvExport(undefined, dto);
  }
}
