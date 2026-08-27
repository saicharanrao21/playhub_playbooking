import { Injectable, Logger } from '@nestjs/common';
import { SmsProvider, SmsOptions, SmsResponse } from '../interfaces/sms-provider.interface';

@Injectable()
export class MockSmsProvider implements SmsProvider {
  private readonly logger = new Logger(MockSmsProvider.name);

  async send(options: SmsOptions): Promise<SmsResponse> {
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
