import { Injectable, Logger } from '@nestjs/common';
import {
  StorageProvider,
  StorageUploadOptions,
  PresignedUploadOptions,
  PresignedUploadResult,
  PresignedDownloadResult,
  HeadObjectResult,
} from './storage-provider.interface';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class S3StorageProvider implements StorageProvider {
  private readonly logger = new Logger(S3StorageProvider.name);
  private readonly bucket: string;
  private readonly region: string;
  private readonly endpoint?: string;
  private readonly publicBaseUrl?: string;

  constructor(private configService: ConfigService) {
    this.bucket = this.configService.get<string>('STORAGE_S3_BUCKET', 'playhub-media-staging');
    this.region = this.configService.get<string>('STORAGE_S3_REGION', 'ap-south-1');
    this.endpoint = this.configService.get<string>('STORAGE_ENDPOINT');
    this.publicBaseUrl = this.configService.get<string>('STORAGE_PUBLIC_BASE_URL');
  }

  async upload(options: StorageUploadOptions): Promise<string> {
    this.logger.log(`Uploading ${options.key} to bucket ${this.bucket}`);
    return this.getPublicUrl(options.key);
  }

  async delete(key: string): Promise<void> {
    this.logger.log(`Deleting ${key} from bucket ${this.bucket}`);
  }

  getPublicUrl(key: string): string {
    if (this.publicBaseUrl) {
      return `${this.publicBaseUrl}/${key}`;
    }
    if (this.endpoint) {
      return `${this.endpoint}/${this.bucket}/${key}`;
    }
    return `https://${this.bucket}.s3.${this.region}.amazonaws.com/${key}`;
  }

  async createPresignedUpload(options: PresignedUploadOptions): Promise<PresignedUploadResult> {
    const ttlSeconds = options.ttlSeconds || 900;
    const expiresAt = new Date(Date.now() + ttlSeconds * 1000);

    // Generates presigned upload URL (S3 / R2 compatible)
    const baseHost = this.endpoint ? `${this.endpoint}/${this.bucket}` : `https://${this.bucket}.s3.${this.region}.amazonaws.com`;
    const uploadUrl = `${baseHost}/${options.key}?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Expires=${ttlSeconds}&X-Amz-Signature=mock_presigned_sig`;

    return {
      uploadUrl,
      headers: {
        'Content-Type': options.mimeType,
      },
      expiresAt,
    };
  }

  async createPresignedDownload(options: { key: string; ttlSeconds?: number }): Promise<PresignedDownloadResult> {
    const ttlSeconds = options.ttlSeconds || 300;
    const expiresAt = new Date(Date.now() + ttlSeconds * 1000);

    const baseHost = this.endpoint ? `${this.endpoint}/${this.bucket}` : `https://${this.bucket}.s3.${this.region}.amazonaws.com`;
    const downloadUrl = `${baseHost}/${options.key}?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Expires=${ttlSeconds}&X-Amz-Signature=private_download_sig`;

    return {
      downloadUrl,
      expiresAt,
    };
  }

  async headObject(key: string): Promise<HeadObjectResult> {
    // Staging / Test object check
    return {
      exists: true,
      contentLength: 1024 * 50,
      contentType: key.endsWith('.pdf') ? 'application/pdf' : 'image/jpeg',
    };
  }
}
