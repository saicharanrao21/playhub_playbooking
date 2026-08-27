import { Injectable, Logger } from '@nestjs/common';
import { WhatsAppProvider, WhatsAppOptions, WhatsAppResponse } from '../interfaces/whatsapp-provider.interface';

@Injectable()
export class MockWhatsAppProvider implements WhatsAppProvider {
  private readonly logger = new Logger(MockWhatsAppProvider.name);

  async send(options: WhatsAppOptions): Promise<WhatsAppResponse> {
    this.logger.log(
      `[MOCK WHATSAPP] Sending template ${options.templateName} to ${options.to} with vars: ${JSON.stringify(
        options.variables,
      )}`,
    );
    return {
      success: true,
      messageId: `mock-wa-${Date.now()}`,
    };
  }

  getName(): string {
    return 'MOCK_WHATSAPP';
  }
}
