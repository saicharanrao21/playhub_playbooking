import { Injectable, Logger } from '@nestjs/common';
import { StorageProvider, StorageUploadOptions } from './storage-provider.interface';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class S3StorageProvider implements StorageProvider {
  private readonly logger = new Logger(S3StorageProvider.name);
  private readonly bucket: string;
  private readonly region: string;

  constructor(private configService: ConfigService) {
    this.bucket = this.configService.get<string>('STORAGE_S3_BUCKET');
    this.region = this.configService.get<string>('STORAGE_S3_REGION', 'us-east-1');
  }

  async upload(options: StorageUploadOptions): Promise<string> {
    this.logger.log(`[MOCK] Uploading ${options.key} to S3 bucket ${this.bucket}`);
    // Real implementation would use @aws-sdk/client-s3
    return `https://${this.bucket}.s3.${this.region}.amazonaws.com/${options.key}`;
  }

  async delete(key: string): Promise<void> {
    this.logger.log(`[MOCK] Deleting ${key} from S3 bucket ${this.bucket}`);
  }

  getPublicUrl(key: string): string {
    const publicUrl = this.configService.get<string>('MEDIA_PUBLIC_BASE_URL');
    if (publicUrl) {
        return `${publicUrl}/${key}`;
    }
    return `https://${this.bucket}.s3.${this.region}.amazonaws.com/${key}`;
  }
}
