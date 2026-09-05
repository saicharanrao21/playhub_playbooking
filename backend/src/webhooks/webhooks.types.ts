export enum WebhookStatus {
  RECEIVED = 'RECEIVED',
  QUEUED = 'QUEUED',
  PROCESSING = 'PROCESSING',
  PROCESSED = 'PROCESSED',
  IGNORED = 'IGNORED',
  FAILED = 'FAILED',
}

export interface WebhookJobPayload {
  webhookEventId: string;
}
