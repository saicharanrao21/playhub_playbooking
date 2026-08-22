import { Injectable, Logger } from '@nestjs/common';
import { StorageProvider, StorageUploadOptions } from './storage-provider.interface';
import { ConfigService } from '@nestjs/config';
import * as fs from 'fs/promises';
import * as path from 'path';

@Injectable()
export class LocalFilesystemStorageProvider implements StorageProvider {
  private readonly logger = new Logger(LocalFilesystemStorageProvider.name);
  private readonly uploadDir: string;
  private readonly publicBaseUrl: string;

  constructor(private configService: ConfigService) {
    this.uploadDir = this.configService.get<string>('STORAGE_LOCAL_DIR', 'uploads');
    this.publicBaseUrl = this.configService.get<string>('MEDIA_PUBLIC_BASE_URL', 'http://localhost:3000/uploads');
    this.ensureUploadDir();
  }

  private async ensureUploadDir() {
    try {
      await fs.access(this.uploadDir);
    } catch {
      await fs.mkdir(this.uploadDir, { recursive: true });
    }
  }

  async upload(options: StorageUploadOptions): Promise<string> {
    const fullPath = path.join(this.uploadDir, options.key);
    const dir = path.dirname(fullPath);

    await fs.mkdir(dir, { recursive: true });
    await fs.writeFile(fullPath, options.buffer);

    return this.getPublicUrl(options.key);
  }

  async delete(key: string): Promise<void> {
    const fullPath = path.join(this.uploadDir, key);
    try {
      await fs.unlink(fullPath);
    } catch (error) {
      this.logger.warn(`Failed to delete local file: ${fullPath}`, error.stack);
    }
  }

  getPublicUrl(key: string): string {
    return `${this.publicBaseUrl}/${key}`;
  }
}
