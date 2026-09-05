import { Module } from '@nestjs/common';
import { AnalyticsService } from './analytics.service';
import { ReportsService } from './reports.service';
import { PartnerAnalyticsController } from './partner-analytics.controller';
import { AdminAnalyticsController } from './admin-analytics.controller';
import { PrismaModule } from '../prisma/prisma.module';
import { OrganizationsModule } from '../organizations/organizations.module';
import { AuditService } from '../common/services/audit.service';
import { STORAGE_PROVIDER } from '../common/storage/storage-provider.interface';
import { LocalFilesystemStorageProvider } from '../common/storage/local-filesystem-storage.provider';
import { S3StorageProvider } from '../common/storage/s3-storage.provider';
import { ConfigService } from '@nestjs/config';

@Module({
  imports: [PrismaModule, OrganizationsModule],
  controllers: [PartnerAnalyticsController, AdminAnalyticsController],
  providers: [
    AnalyticsService,
    ReportsService,
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
  exports: [AnalyticsService, ReportsService],
})
export class AnalyticsModule {}
