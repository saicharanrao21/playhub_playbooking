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
import { ChatService } from './chat.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserIdentity } from '../common/interfaces/user-identity.interface';

@ApiTags('chat')
@Controller('matches/:matchId/chat')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth()
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Get('messages')
  @ApiOperation({ summary: 'Get paginated chat message history for match/booking' })
  async getMessages(
    @Param('matchId') matchId: string,
    @Query('skip') skip?: number,
    @Query('take') take?: number,
  ) {
    return this.chatService.getConversationMessages(matchId, Number(skip || 0), Number(take || 50));
  }

  @Post('court-arrival')
  @ApiOperation({ summary: 'REST fallback: Register real-time court arrival' })
  async registerCourtArrival(
    @CurrentUser() user: UserIdentity,
    @Param('matchId') matchId: string,
    @Body('notes') notes?: string,
  ) {
    return this.chatService.registerCourtArrival(user.userId, matchId, notes);
  }
}
