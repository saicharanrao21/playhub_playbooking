import { Injectable, Logger, InternalServerErrorException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PushProvider, PushOptions, PushResponse } from '../interfaces/push-provider.interface';

@Injectable()
export class MockPushProvider implements PushProvider {
  private readonly logger = new Logger(MockPushProvider.name);

  constructor(private configService: ConfigService) {}

  async send(options: PushOptions): Promise<PushResponse> {
    if (this.configService.get('NODE_ENV') === 'production') {
      throw new InternalServerErrorException('MockPushProvider is not allowed in production');
    }

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
