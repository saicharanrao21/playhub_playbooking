import { Controller, Get, Post, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PlatformAdminGuard } from '../common/guards/platform-admin.guard';

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

  @Post('businesses/:id/approve')
  @ApiOperation({ summary: 'Approve a pending business' })
  approveBusiness(@Param('id') id: string) {
    return this.adminService.approveBusiness(id);
  }
}
