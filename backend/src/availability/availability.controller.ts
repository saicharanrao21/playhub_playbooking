import { Controller, Get, Query, UseGuards, Param, ParseIntPipe } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader, ApiQuery } from '@nestjs/swagger';
import { AvailabilityService } from './availability.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OrganizationGuard } from '../common/guards/organization.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { OrganizationContext } from '../common/decorators/organization-context.decorator';

@ApiTags('availability')
@Controller('organizations/:organizationId/availability')
@UseGuards(JwtAuthGuard, OrganizationGuard, PermissionsGuard)
@ApiBearerAuth()
@ApiHeader({ name: 'x-organization-id', required: false })
export class AvailabilityController {
  constructor(private readonly availabilityService: AvailabilityService) {}

  @Get('facilities/:facilityId')
  @ApiOperation({ summary: 'Get availability for a specific facility' })
  @ApiQuery({ name: 'date', example: '2026-08-20', description: 'Date in YYYY-MM-DD format' })
  @ApiQuery({ name: 'duration', required: false, example: 60, description: 'Duration in minutes' })
  async getAvailability(
    @OrganizationContext() organizationId: string,
    @Param('facilityId') facilityId: string,
    @Query('date') date: string,
    @Query('duration') duration?: string,
  ) {
    const durationMinutes = duration ? parseInt(duration) : 60;
    return this.availabilityService.getAvailability(
      organizationId,
      facilityId,
      date,
      durationMinutes,
    );
  }
}
