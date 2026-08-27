export interface SmsOptions {
  to: string;
  message: string;
}

export interface SmsResponse {
  success: boolean;
  messageId?: string;
  error?: string;
}

export interface SmsProvider {
  send(options: SmsOptions): Promise<SmsResponse>;
  getName(): string;
}
