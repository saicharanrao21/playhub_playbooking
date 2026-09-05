import { Module } from '@nestjs/common';
import { MediaService } from './media.service';
import { MediaController } from './media.controller';
import { STORAGE_PROVIDER } from '../common/storage/storage-provider.interface';
import { LocalFilesystemStorageProvider } from '../common/storage/local-filesystem-storage.provider';
import { S3StorageProvider } from '../common/storage/s3-storage.provider';
import { ConfigService } from '@nestjs/config';
import { OrganizationsModule } from '../organizations/organizations.module';
import { AuditService } from '../common/services/audit.service';

@Module({
  imports: [OrganizationsModule],
  controllers: [MediaController],
  providers: [
    MediaService,
    AuditService,
    {
      provide: STORAGE_PROVIDER,
      useFactory: (config: ConfigService) => {
        const provider = config.get<string>('STORAGE_PROVIDER', config.get<string>('MEDIA_STORAGE_PROVIDER', 's3'));
        return provider === 'local'
          ? new LocalFilesystemStorageProvider(config)
          : new S3StorageProvider(config);
      },
      inject: [ConfigService],
    },
  ],
  exports: [MediaService],
})
export class MediaModule {}
