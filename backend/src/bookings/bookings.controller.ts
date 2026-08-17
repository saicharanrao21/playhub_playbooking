import { Controller, Get, Post, Body, UseGuards, Param, Query, Patch, Req } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader, ApiQuery } from '@nestjs/swagger';
import { BookingsService } from './bookings.service';
import { CreateBookingDto } from './dto/create-booking.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OrganizationGuard } from '../common/guards/organization.guard';
import { OrganizationContext } from '../common/decorators/organization-context.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserIdentity } from '../common/interfaces/user-identity.interface';

@ApiTags('bookings')
@Controller('organizations/:organizationId/bookings')
@UseGuards(JwtAuthGuard, OrganizationGuard)
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
  @ApiOperation({ summary: 'List bookings' })
  @ApiQuery({ name: 'userId', required: false })
  @ApiQuery({ name: 'facilityId', required: false })
  async findAll(
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
  ) {
    return this.bookingsService.findOne(organizationId, id);
  }

  @Patch(':id/cancel')
  @ApiOperation({ summary: 'Cancel a booking' })
  async cancel(
    @OrganizationContext() organizationId: string,
    @Param('id') id: string,
  ) {
    return this.bookingsService.cancel(organizationId, id);
  }
}
