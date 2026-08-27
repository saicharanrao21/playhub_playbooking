export interface EmailOptions {
  to: string;
  subject: string;
  html: string;
  text?: string;
  from?: string;
}

export interface EmailResponse {
  success: boolean;
  messageId?: string;
  error?: string;
}

export interface EmailProvider {
  send(options: EmailOptions): Promise<EmailResponse>;
  getName(): string;
}
