export interface StorageUploadOptions {
  key: string;
  buffer: Buffer;
  mimeType: string;
  isPublic?: boolean;
}

export interface StorageProvider {
  upload(options: StorageUploadOptions): Promise<string>;
  delete(key: string): Promise<void>;
  getPublicUrl(key: string): string;
}

export const STORAGE_PROVIDER = 'STORAGE_PROVIDER';
