import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EmailProvider, EmailOptions, EmailResponse } from '../interfaces/email-provider.interface';

@Injectable()
export class ResendEmailProvider implements EmailProvider {
  private readonly logger = new Logger(ResendEmailProvider.name);
  private readonly apiKey: string;
  private readonly fromDefault: string;

  constructor(private configService: ConfigService) {
    this.apiKey = this.configService.get<string>('RESEND_API_KEY');
    this.fromDefault = this.configService.get<string>('EMAIL_FROM', 'PlayHub <notifications@playhub.app>');
  }

  async send(options: EmailOptions): Promise<EmailResponse> {
    if (!this.apiKey || this.configService.get('NODE_ENV') === 'development') {
      this.logger.log(`[MOCK EMAIL] To: ${options.to}, Subject: ${options.subject}`);
      return { success: true, messageId: `mock-email-${Date.now()}` };
    }

    try {
      const response = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${this.apiKey}`,
        },
        body: JSON.stringify({
          from: options.from || this.fromDefault,
          to: options.to,
          subject: options.subject,
          html: options.html,
          text: options.text,
        }),
      });

      const data = await response.json();

      if (!response.ok) {
        this.logger.error(`Resend API error: ${JSON.stringify(data)}`);
        return { success: false, error: data.message || 'Failed to send email' };
      }

      return { success: true, messageId: data.id };
    } catch (error) {
      this.logger.error(`Failed to send email via Resend: ${error.message}`);
      return { success: false, error: error.message };
    }
  }

  getName(): string {
    return 'RESEND';
  }
}
