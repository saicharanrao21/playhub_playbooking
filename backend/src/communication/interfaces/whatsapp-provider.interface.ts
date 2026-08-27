export interface WhatsAppOptions {
  to: string;
  templateName: string;
  variables: Record<string, string>;
}

export interface WhatsAppResponse {
  success: boolean;
  messageId?: string;
  error?: string;
}

export interface WhatsAppProvider {
  send(options: WhatsAppOptions): Promise<WhatsAppResponse>;
  getName(): string;
}
