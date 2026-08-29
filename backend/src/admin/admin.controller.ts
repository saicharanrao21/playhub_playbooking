import { Controller, Get, Post, Param, Body, UseGuards, Query } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PlatformAdminGuard } from '../common/guards/platform-admin.guard';
import { ReviewPartnerDto } from './dto/review-partner.dto';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserIdentity } from '../common/interfaces/user-identity.interface';
import { PaginationDto } from '../common/dto/pagination.dto';
import { KYCStatus, OrganizationStatus } from '@prisma/client';

@ApiTags('admin')
@Controller('admin')
@UseGuards(JwtAuthGuard, PlatformAdminGuard)
@ApiBearerAuth()
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  @Get('dashboard/stats')
  @ApiOperation({ summary: 'Get platform-wide dashboard statistics' })
  getDashboardStats() {
    return this.adminService.getDashboardStats();
  }

  @Get('partners')
  @ApiOperation({ summary: 'List partner organizations with filtering' })
  @ApiQuery({ name: 'kycStatus', enum: KYCStatus, required: false })
  @ApiQuery({ name: 'status', enum: OrganizationStatus, required: false })
  getPartners(
    @Query() pagination: PaginationDto,
    @Query('kycStatus') kycStatus?: KYCStatus,
    @Query('status') status?: OrganizationStatus,
  ) {
    return this.adminService.getPartners({
      kycStatus,
      status,
      skip: pagination.skip,
      take: pagination.limit,
    });
  }

  @Get('partners/:id')
  @ApiOperation({ summary: 'Get comprehensive partner details' })
  getPartnerDetails(@Param('id') id: string) {
    return this.adminService.getPartnerDetails(id);
  }

  @Post('partners/:id/review')
  @ApiOperation({ summary: 'Review partner KYC and status' })
  reviewPartner(
    @CurrentUser() admin: UserIdentity,
    @Param('id') id: string,
    @Body() dto: ReviewPartnerDto,
  ) {
    return this.adminService.reviewPartner(admin.userId, id, dto);
  }

  @Get('audit-logs')
  @ApiOperation({ summary: 'Get platform-wide audit logs' })
  getAuditLogs(@Query() pagination: PaginationDto) {
    return this.adminService.getAuditLogs({
      skip: pagination.skip,
      take: pagination.limit,
    });
  }

  @Post('businesses/:id/approve')
  @ApiOperation({ summary: 'Legacy: Approve a pending business' })
  approveBusiness(@Param('id') id: string) {
    return this.adminService.approveBusiness(id);
  }
}
