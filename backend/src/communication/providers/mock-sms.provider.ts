import { Injectable, Logger, InternalServerErrorException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { SmsProvider, SmsOptions, SmsResponse } from '../interfaces/sms-provider.interface';

@Injectable()
export class MockSmsProvider implements SmsProvider {
  private readonly logger = new Logger(MockSmsProvider.name);

  constructor(private configService: ConfigService) {}

  async send(options: SmsOptions): Promise<SmsResponse> {
    if (this.configService.get('NODE_ENV') === 'production') {
      throw new InternalServerErrorException('MockSmsProvider is not allowed in production');
    }

    this.logger.log(`[MOCK SMS] Sending to ${options.to}: ${options.message}`);
    return {
      success: true,
      messageId: `mock-sms-${Date.now()}`,
    };
  }

  getName(): string {
    return 'MOCK_SMS';
  }
}
