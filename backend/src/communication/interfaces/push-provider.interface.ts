export interface PushOptions {
  tokens: string[];
  title: string;
  body: string;
  data?: Record<string, string>;
}

export interface PushResponse {
  success: boolean;
  failureCount: number;
  successCount: number;
  results?: Array<{ token: string; success: boolean; error?: string }>;
}

export interface PushProvider {
  send(options: PushOptions): Promise<PushResponse>;
  getName(): string;
}
