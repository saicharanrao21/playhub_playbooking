import { Controller, Get, Post, Body, UseGuards, Param, Query, Patch, Req } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader, ApiQuery } from '@nestjs/swagger';
import { BookingsService } from './bookings.service';
import { CreateBookingDto } from './dto/create-booking.dto';
import { RescheduleBookingDto } from './dto/reschedule-booking.dto';
import { CancelBookingDto } from './dto/cancel-booking.dto';
import { CheckInDto } from './dto/check-in.dto';
import { PaginationDto } from '../common/dto/pagination.dto';
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
    @Query() pagination: PaginationDto,
    @Query('facilityId') facilityId?: string,
  ) {
    return this.bookingsService.findAll(organizationId, {
      userId: user.userId,
      facilityId,
      skip: pagination.skip,
      take: pagination.limit,
    });
  }

  @Get('all')
  @RequirePermission(Permissions.BOOKING_READ)
  @ApiOperation({ summary: 'List all bookings in the organization (Admin/Operator only)' })
  @ApiQuery({ name: 'userId', required: false })
  @ApiQuery({ name: 'facilityId', required: false })
  async findAllAdmin(
    @OrganizationContext() organizationId: string,
    @Query() pagination: PaginationDto,
    @Query('userId') userId?: string,
    @Query('facilityId') facilityId?: string,
  ) {
    return this.bookingsService.findAll(organizationId, {
      userId,
      facilityId,
      skip: pagination.skip,
      take: pagination.limit,
    });
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

  @Post(':id/accept')
  @RequirePermission(Permissions.BOOKING_ACCEPT)
  @ApiOperation({ summary: 'Accept/Approve a pending booking (Partner only)' })
  async accept(
    @OrganizationContext() organizationId: string,
    @Param('id') id: string,
  ) {
    return this.bookingsService.accept(organizationId, id);
  }

  @Post(':id/reject')
  @RequirePermission(Permissions.BOOKING_REJECT)
  @ApiOperation({ summary: 'Reject a pending booking (Partner only)' })
  async reject(
    @OrganizationContext() organizationId: string,
    @Param('id') id: string,
    @Body() dto: CancelBookingDto,
  ) {
    return this.bookingsService.reject(organizationId, id, dto.reason);
  }

  @Post('check-in')
  @RequirePermission(Permissions.BOOKING_CHECKIN)
  @ApiOperation({ summary: 'Check in a user via QR pass (Partner/Staff only)' })
  async checkIn(
    @OrganizationContext() organizationId: string,
    @CurrentUser() staff: UserIdentity,
    @Body() dto: CheckInDto,
  ) {
    return this.bookingsService.checkIn(organizationId, staff.userId, dto.qrToken);
  }

  @Post(':id/no-show')
  @RequirePermission(Permissions.BOOKING_NOSHOW)
  @ApiOperation({ summary: 'Mark a booking as no-show (Partner only)' })
  async noShow(
    @OrganizationContext() organizationId: string,
    @Param('id') id: string,
  ) {
    return this.bookingsService.noShow(organizationId, id);
  }

  @Post(':id/complete')
  @RequirePermission(Permissions.BOOKING_COMPLETE)
  @ApiOperation({ summary: 'Mark a booking as completed (Partner only)' })
  async complete(
    @OrganizationContext() organizationId: string,
    @Param('id') id: string,
  ) {
    return this.bookingsService.complete(organizationId, id);
  }

  @Get(':id/qr-pass')
  @ApiOperation({ summary: 'Get a temporary QR token for check-in' })
  async getQrPass(
    @OrganizationContext() organizationId: string,
    @Param('id') id: string,
    @CurrentUser() user: UserIdentity,
  ) {
    return this.bookingsService.getQrPass(organizationId, id, user.userId);
  }
}
