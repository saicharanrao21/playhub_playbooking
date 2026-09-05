import {
  Injectable,
  BadRequestException,
  ForbiddenException,
  NotFoundException,
  Inject,
  Logger,
  Optional,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { STORAGE_PROVIDER, StorageProvider } from '../common/storage/storage-provider.interface';
import { MediaType, Prisma } from '@prisma/client';
import { PresignUploadDto, MediaCategory, MediaEntityType } from './dto/presign-upload.dto';
import { AuditService } from '../common/services/audit.service';
import { QueueService } from '../queues/queue.service';
import { MetricsService } from '../observability/metrics.service';
import * as path from 'path';
import * as crypto from 'crypto';

@Injectable()
export class MediaService {
  private readonly logger = new Logger(MediaService.name);

  private readonly ALLOWED_IMAGE_MIMES = ['image/jpeg', 'image/png', 'image/webp'];
  private readonly ALLOWED_KYC_MIMES = ['application/pdf', 'image/jpeg', 'image/png'];
  private readonly MAX_IMAGE_SIZE = 10 * 1024 * 1024; // 10MB
  private readonly MAX_KYC_SIZE = 15 * 1024 * 1024;   // 15MB

  constructor(
    private prisma: PrismaService,
    @Inject(STORAGE_PROVIDER) private storageProvider: StorageProvider,
    private auditService: AuditService,
    @Optional() private queueService?: QueueService,
    @Optional() private metricsService?: MetricsService,
  ) {}

  /**
   * Generates a short-lived presigned upload URL directly to S3/R2 object storage.
   * Validates MIME type, file size, and organization entity ownership.
   */
  async requestPresignedUpload(organizationId: string, userId: string, dto: PresignUploadDto) {
    const { category, entityType, entityId, filename, mimeType, fileSize } = dto;

    // 1. Validate Category Rules & MIME Types
    if (category === MediaCategory.KYC_DOCUMENT) {
      if (!this.ALLOWED_KYC_MIMES.includes(mimeType)) {
        throw new BadRequestException(`Invalid KYC document type [${mimeType}]. Allowed: PDF, JPEG, PNG.`);
      }
      if (fileSize > this.MAX_KYC_SIZE) {
        throw new BadRequestException(`KYC document size exceeds limit of 15MB.`);
      }
    } else {
      if (!this.ALLOWED_IMAGE_MIMES.includes(mimeType)) {
        throw new BadRequestException(`Invalid image type [${mimeType}]. Allowed: JPEG, PNG, WEBP.`);
      }
      if (fileSize > this.MAX_IMAGE_SIZE) {
        throw new BadRequestException(`Image size exceeds limit of 10MB.`);
      }
    }

    // 2. Validate Entity Ownership by Organization
    await this.validateEntityOwnership(organizationId, entityType, entityId);

    // 3. Generate Server-Authoritative Object Key
    const mediaId = crypto.randomUUID();
    const ext = path.extname(filename) || (mimeType === 'application/pdf' ? '.pdf' : '.jpg');
    const isPrivate = category === MediaCategory.KYC_DOCUMENT;

    let storageKey = '';
    if (category === MediaCategory.KYC_DOCUMENT) {
      storageKey = `organizations/${organizationId}/kyc/${entityId}/${mediaId}${ext}`;
    } else if (entityType === MediaEntityType.VENUE) {
      storageKey = `organizations/${organizationId}/venues/${entityId}/media/${mediaId}${ext}`;
    } else if (entityType === MediaEntityType.FACILITY) {
      storageKey = `organizations/${organizationId}/facilities/${entityId}/media/${mediaId}${ext}`;
    } else {
      storageKey = `organizations/${organizationId}/media/${mediaId}${ext}`;
    }

    const publicUrl = isPrivate ? '' : this.storageProvider.getPublicUrl(storageKey);

    // 4. Create Media Record in UPLOAD_PENDING Status
    const media = await this.prisma.media.create({
      data: {
        id: mediaId,
        organizationId,
        category,
        entityType,
        entityId,
        venueId: entityType === MediaEntityType.VENUE ? entityId : null,
        facilityId: entityType === MediaEntityType.FACILITY ? entityId : null,
        userId,
        url: publicUrl,
        storageKey,
        storageProvider: 's3',
        mimeType,
        fileSize,
        type: mimeType === 'application/pdf' ? MediaType.DOCUMENT : MediaType.IMAGE,
        visibility: isPrivate ? 'PRIVATE' : 'PUBLIC',
        status: 'UPLOAD_PENDING',
      },
    });

    // 5. Generate Presigned Upload Result
    const presigned = await this.storageProvider.createPresignedUpload({
      key: storageKey,
      mimeType,
      fileSize,
      ttlSeconds: 900, // 15 minutes
    });

    if (this.metricsService) {
      this.metricsService.cacheOperationsTotal.inc({ operation: 'presign', result: 'success' });
    }

    return {
      mediaId: media.id,
      objectKey: storageKey,
      uploadUrl: presigned.uploadUrl,
      method: 'PUT',
      headers: presigned.headers,
      expiresAt: presigned.expiresAt,
    };
  }

  /**
   * Finalizes media upload after client directly pushes binary to object storage.
   */
  async completeUpload(organizationId: string, mediaId: string) {
    const media = await this.prisma.media.findFirst({
      where: { id: mediaId, organizationId },
    });

    if (!media) {
      throw new NotFoundException('Media record not found or unauthorized');
    }

    // Verify Object Existence in S3/R2
    const head = await this.storageProvider.headObject(media.storageKey);
    if (!head.exists) {
      await this.prisma.media.update({
        where: { id: mediaId },
        data: { status: 'FAILED' },
      });
      throw new BadRequestException('Binary object was not found in storage. Upload incomplete.');
    }

    // Update Status to READY (or PROCESSING)
    const isImage = media.type === MediaType.IMAGE;
    const nextStatus = isImage ? 'READY' : 'READY';

    const updated = await this.prisma.media.update({
      where: { id: mediaId },
      data: {
        status: nextStatus,
        fileSize: head.contentLength || media.fileSize,
        url: media.visibility === 'PUBLIC' ? this.storageProvider.getPublicUrl(media.storageKey) : '',
      },
    });

    await this.auditService.record({
      organizationId,
      action: 'media:upload_completed',
      resource: 'media',
      resourceId: mediaId,
      payload: { category: media.category, key: media.storageKey },
      status: 'success',
    });

    return updated;
  }

  /**
   * Secure short-lived presigned download URL for private KYC documents.
   */
  async getPrivateDownloadUrl(organizationId: string, mediaId: string, isPlatformAdmin: boolean = false) {
    const media = await this.prisma.media.findUnique({
      where: { id: mediaId },
    });

    if (!media) {
      throw new NotFoundException('Media document not found');
    }

    if (!isPlatformAdmin && media.organizationId !== organizationId) {
      throw new ForbiddenException('Unauthorized access to private document');
    }

    const presigned = await this.storageProvider.createPresignedDownload({
      key: media.storageKey,
      ttlSeconds: 300, // 5 minutes
    });

    await this.auditService.record({
      organizationId: media.organizationId,
      action: 'media:kyc_download_accessed',
      resource: 'media',
      resourceId: mediaId,
      status: 'success',
    });

    return {
      mediaId,
      downloadUrl: presigned.downloadUrl,
      expiresAt: presigned.expiresAt,
    };
  }

  async deleteMedia(organizationId: string, mediaId: string) {
    const media = await this.prisma.media.findFirst({
      where: { id: mediaId, organizationId },
    });

    if (!media) {
      throw new NotFoundException('Media not found');
    }

    // 1. Delete from storage
    await this.storageProvider.delete(media.storageKey);

    // 2. Soft delete / remove from DB
    return this.prisma.media.delete({
      where: { id: mediaId },
    });
  }

  private async validateEntityOwnership(organizationId: string, entityType: MediaEntityType, entityId: string) {
    if (entityType === MediaEntityType.VENUE) {
      const venue = await this.prisma.venue.findFirst({
        where: { id: entityId, business: { organizationId } },
      });
      if (!venue) throw new ForbiddenException('Unauthorized venue entity context');
    } else if (entityType === MediaEntityType.FACILITY) {
      const facility = await this.prisma.facility.findFirst({
        where: { id: entityId, venue: { business: { organizationId } } },
      });
      if (!facility) throw new ForbiddenException('Unauthorized facility entity context');
    } else if (entityType === MediaEntityType.ORGANIZATION) {
      if (entityId !== organizationId) throw new ForbiddenException('Unauthorized organization entity context');
    }
  }

  // Legacy fallback method for direct multipart uploads
  async uploadVenueImage(organizationId: string, venueId: string, file: any) {
    const presign = await this.requestPresignedUpload(organizationId, 'system', {
      category: MediaCategory.VENUE_MEDIA,
      entityType: MediaEntityType.VENUE,
      entityId: venueId,
      filename: file.originalname || 'venue.jpg',
      mimeType: file.mimetype,
      fileSize: file.size,
    });

    await this.storageProvider.upload({
      key: presign.objectKey,
      buffer: file.buffer,
      mimeType: file.mimetype,
      isPublic: true,
    });

    return this.completeUpload(organizationId, presign.mediaId);
  }

  async uploadFacilityImage(organizationId: string, facilityId: string, file: any) {
    const presign = await this.requestPresignedUpload(organizationId, 'system', {
      category: MediaCategory.FACILITY_MEDIA,
      entityType: MediaEntityType.FACILITY,
      entityId: facilityId,
      filename: file.originalname || 'facility.jpg',
      mimeType: file.mimetype,
      fileSize: file.size,
    });

    await this.storageProvider.upload({
      key: presign.objectKey,
      buffer: file.buffer,
      mimeType: file.mimetype,
      isPublic: true,
    });

    return this.completeUpload(organizationId, presign.mediaId);
  }
}
