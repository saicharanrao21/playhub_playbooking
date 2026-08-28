import {
  Controller,
  Post,
  Body,
  Get,
  UseGuards,
  Patch,
  Param,
  Delete
} from '@nestjs/common';
import { CommunicationService } from './communication.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserIdentity } from '../common/interfaces/user-identity.interface';
import { RegisterDeviceDto } from './dto/register-device.dto';
import { CommunicationChannel, CommunicationCategory } from '@prisma/client';

@Controller('communication')
@UseGuards(JwtAuthGuard)
export class CommunicationController {
  constructor(private readonly communicationService: CommunicationService) {}

  @Post('devices')
  async registerDevice(@CurrentUser() user: UserIdentity, @Body() dto: RegisterDeviceDto) {
    return this.communicationService.registerDevice(user.userId, dto.token, dto.platform);
  }

  @Delete('devices/:token')
  async unregisterDevice(@CurrentUser() user: UserIdentity, @Param('token') token: string) {
    return this.communicationService.unregisterDevice(user.userId, token);
  }

  @Get('preferences')
  async getPreferences(@CurrentUser() user: UserIdentity) {
    return this.communicationService.getPreferences(user.userId);
  }

  @Patch('preferences')
  async updatePreference(
    @CurrentUser() user: UserIdentity,
    @Body() body: { category: CommunicationCategory; channel: CommunicationChannel; isEnabled: boolean }
  ) {
    return this.communicationService.updatePreference(
      user.userId,
      body.category,
      body.channel,
      body.isEnabled,
    );
  }
}
