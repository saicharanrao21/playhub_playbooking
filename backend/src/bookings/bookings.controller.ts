import { Controller, Get, Post, Body, UseGuards, Param, Query, Patch, Req } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader, ApiQuery } from '@nestjs/swagger';
import { BookingsService } from './bookings.service';
import { CreateBookingDto } from './dto/create-booking.dto';
import { RescheduleBookingDto } from './dto/reschedule-booking.dto';
import { CancelBookingDto } from './dto/cancel-booking.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OrganizationGuard } from '../common/guards/organization.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { Permissions } from '../common/constants/permissions';
import { OrganizationContext } from '../common/decorators/organization-context.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserIdentity } from '../common/interfaces/user-identity.interface';

@ApiTags('bookings')
@Controller('organizations/:organizationId/bookings')
@UseGuards(JwtAuthGuard, OrganizationGuard, PermissionsGuard)
@ApiBearerAuth()
@ApiHeader({ name: 'x-organization-id', required: false })
@ApiHeader({ name: 'x-idempotency-key', required: false })
export class BookingsController {
  constructor(private readonly bookingsService: BookingsService) {}

  @Post(':facilityId')
  @ApiOperation({ summary: 'Create a new booking for a facility' })
  async create(
    @OrganizationContext() organizationId: string,
    @CurrentUser() user: UserIdentity,
    @Param('facilityId') facilityId: string,
    @Body() dto: CreateBookingDto,
    @Req() req: any,
  ) {
    const idempotencyKey = req.headers['x-idempotency-key'];
    return this.bookingsService.create(organizationId, user.userId, facilityId, dto, idempotencyKey);
  }

  @Get()
  @ApiOperation({ summary: 'List bookings for the authenticated user' })
  @ApiQuery({ name: 'facilityId', required: false })
  async findAll(
    @OrganizationContext() organizationId: string,
    @CurrentUser() user: UserIdentity,
    @Query('facilityId') facilityId?: string,
  ) {
    return this.bookingsService.findAll(organizationId, { userId: user.userId, facilityId });
  }

  @Get('all')
  @RequirePermission(Permissions.BOOKING_READ)
  @ApiOperation({ summary: 'List all bookings in the organization (Admin/Operator only)' })
  @ApiQuery({ name: 'userId', required: false })
  @ApiQuery({ name: 'facilityId', required: false })
  async findAllAdmin(
    @OrganizationContext() organizationId: string,
    @Query('userId') userId?: string,
    @Query('facilityId') facilityId?: string,
  ) {
    return this.bookingsService.findAll(organizationId, { userId, facilityId });
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get a specific booking' })
  async findOne(
    @OrganizationContext() organizationId: string,
    @Param('id') id: string,
    @CurrentUser() user: UserIdentity,
  ) {
    // If not privileged, enforce ownership check via userId
    const isPrivileged = user.roles.includes('ADMIN') || user.roles.includes('BUSINESS_OWNER');
    const userId = isPrivileged ? undefined : user.userId;
    return this.bookingsService.findOne(organizationId, id, userId);
  }

  @Patch(':id/cancel')
  @ApiOperation({ summary: 'Cancel a booking' })
  async cancel(
    @OrganizationContext() organizationId: string,
    @Param('id') id: string,
    @Body() dto: CancelBookingDto,
    @CurrentUser() user: UserIdentity,
  ) {
    // If not privileged, enforce ownership check via userId
    const isPrivileged = user.roles.includes('ADMIN') || user.roles.includes('BUSINESS_OWNER');
    const userId = isPrivileged ? undefined : user.userId;
    return this.bookingsService.cancel(organizationId, id, dto.reason, userId);
  }

  @Patch(':id/reschedule')
  @ApiOperation({ summary: 'Reschedule a booking' })
  async reschedule(
    @OrganizationContext() organizationId: string,
    @CurrentUser() user: UserIdentity,
    @Param('id') id: string,
    @Body() dto: RescheduleBookingDto,
  ) {
    // If not privileged, enforce ownership check via userId
    const isPrivileged = user.roles.includes('ADMIN') || user.roles.includes('BUSINESS_OWNER');
    const userId = isPrivileged ? undefined : user.userId;

    return this.bookingsService.reschedule(organizationId, id, dto, userId);
  }
}
