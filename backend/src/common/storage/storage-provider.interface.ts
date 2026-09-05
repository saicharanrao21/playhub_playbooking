export interface StorageUploadOptions {
  key: string;
  buffer: Buffer;
  mimeType: string;
  isPublic?: boolean;
}

export interface PresignedUploadOptions {
  key: string;
  mimeType: string;
  fileSize: number;
  ttlSeconds?: number;
}

export interface PresignedUploadResult {
  uploadUrl: string;
  headers?: Record<string, string>;
  expiresAt: Date;
}

export interface PresignedDownloadResult {
  downloadUrl: string;
  expiresAt: Date;
}

export interface HeadObjectResult {
  exists: boolean;
  contentLength?: number;
  contentType?: string;
}

export interface StorageProvider {
  upload(options: StorageUploadOptions): Promise<string>;
  delete(key: string): Promise<void>;
  getPublicUrl(key: string): string;
  createPresignedUpload(options: PresignedUploadOptions): Promise<PresignedUploadResult>;
  createPresignedDownload(options: { key: string; ttlSeconds?: number }): Promise<PresignedDownloadResult>;
  headObject(key: string): Promise<HeadObjectResult>;
}

export const STORAGE_PROVIDER = 'STORAGE_PROVIDER';
