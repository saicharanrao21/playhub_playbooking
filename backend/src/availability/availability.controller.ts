import { Controller, Get, Query, UseGuards, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { AvailabilityService } from './availability.service';
import { GetAvailabilityDto } from './dto/get-availability.dto';
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
  async getAvailability(
    @OrganizationContext() organizationId: string,
    @Param('facilityId') facilityId: string,
    @Query() dto: GetAvailabilityDto,
  ) {
    return this.availabilityService.getAvailability(
      organizationId,
      facilityId,
      dto.date,
      dto.duration,
    );
  }
}
