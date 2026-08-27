import { Injectable, Logger } from '@nestjs/common';
import { PushProvider, PushOptions, PushResponse } from '../interfaces/push-provider.interface';

@Injectable()
export class MockPushProvider implements PushProvider {
  private readonly logger = new Logger(MockPushProvider.name);

  async send(options: PushOptions): Promise<PushResponse> {
    this.logger.log(`[MOCK PUSH] Sending "${options.title}" to ${options.tokens.length} devices`);
    return {
      success: true,
      successCount: options.tokens.length,
      failureCount: 0,
    };
  }

  getName(): string {
    return 'MOCK_PUSH';
  }
}
