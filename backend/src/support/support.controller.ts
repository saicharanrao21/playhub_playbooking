import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { SupportService } from './support.service';
import { DisputesService } from './disputes.service';
import { CreateTicketDto } from './dto/create-ticket.dto';
import { CreateDisputeDto } from './dto/create-dispute.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserIdentity } from '../common/interfaces/user-identity.interface';

@ApiTags('support')
@Controller()
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class SupportController {
  constructor(
    private readonly supportService: SupportService,
    private readonly disputesService: DisputesService,
  ) {}

  @Post('support/tickets')
  @ApiOperation({ summary: 'Customer: Create support ticket' })
  async createTicket(
    @CurrentUser() user: UserIdentity,
    @Body() dto: CreateTicketDto,
  ) {
    return this.supportService.createTicket(user.userId, dto);
  }

  @Get('support/tickets')
  @ApiOperation({ summary: 'Customer: List my support tickets' })
  async getUserTickets(
    @CurrentUser() user: UserIdentity,
    @Query('skip') skip?: number,
    @Query('take') take?: number,
  ) {
    return this.supportService.getUserTickets(user.userId, Number(skip || 0), Number(take || 20));
  }

  @Get('support/tickets/:id')
  @ApiOperation({ summary: 'Customer/Staff: Get support ticket details and messages' })
  async getTicketDetails(
    @CurrentUser() user: UserIdentity,
    @Param('id') id: string,
  ) {
    return this.supportService.getTicketDetails(user.userId, id);
  }

  @Post('support/tickets/:id/messages')
  @ApiOperation({ summary: 'Customer/Staff: Reply message to ticket' })
  async addMessage(
    @CurrentUser() user: UserIdentity,
    @Param('id') id: string,
    @Body('body') body: string,
    @Body('attachments') attachments?: any,
  ) {
    return this.supportService.addMessage(user.userId, 'CUSTOMER', id, body, attachments);
  }

  @Post('bookings/:bookingId/disputes')
  @ApiOperation({ summary: 'Customer: Open formal dispute for a booking' })
  async createDispute(
    @CurrentUser() user: UserIdentity,
    @Param('bookingId') bookingId: string,
    @Body() dto: CreateDisputeDto,
  ) {
    return this.disputesService.createDispute(user.userId, { ...dto, bookingId });
  }

  @Get('disputes/:id')
  @ApiOperation({ summary: 'Customer/Staff: Get dispute case details' })
  async getDisputeById(
    @CurrentUser() user: UserIdentity,
    @Param('id') id: string,
  ) {
    return this.disputesService.getDisputeById(user.userId, id);
  }
}
