import { Injectable, BadRequestException, ForbiddenException, NotFoundException, Inject } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { STORAGE_PROVIDER, StorageProvider } from '../common/storage/storage-provider.interface';
import { MediaType } from '@prisma/client';
import * as path from 'path';
import * as crypto from 'crypto';

@Injectable()
export class MediaService {
  private readonly ALLOWED_IMAGE_MIME_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
  private readonly MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5MB

  constructor(
    private prisma: PrismaService,
    @Inject(STORAGE_PROVIDER) private storageProvider: StorageProvider,
  ) {}

  async uploadVenueImage(organizationId: string, venueId: string, file: any) {
    // 1. Verify Venue Ownership
    const venue = await this.prisma.venue.findFirst({
      where: { id: venueId, business: { organizationId } },
    });
    if (!venue) {
      throw new NotFoundException('Venue not found or unauthorized');
    }

    // 2. Validate File
    this.validateImage(file);

    // 3. Store File
    const mediaId = crypto.randomUUID();
    const ext = path.extname(file.originalname) || '.jpg';
    const key = `${organizationId}/venues/${venueId}/${mediaId}${ext}`;

    const url = await this.storageProvider.upload({
      key,
      buffer: file.buffer,
      mimeType: file.mimetype,
      isPublic: true,
    });

    // 4. Persist Metadata
    return this.prisma.media.create({
      data: {
        id: mediaId,
        organizationId,
        venueId,
        url,
        storageKey: key,
        mimeType: file.mimetype,
        fileSize: file.size,
        type: MediaType.IMAGE,
      },
    });
  }

  async uploadFacilityImage(organizationId: string, facilityId: string, file: any) {
    const facility = await this.prisma.facility.findFirst({
      where: { id: facilityId, venue: { business: { organizationId } } },
    });
    if (!facility) {
      throw new NotFoundException('Facility not found or unauthorized');
    }

    this.validateImage(file);

    const mediaId = crypto.randomUUID();
    const ext = path.extname(file.originalname) || '.jpg';
    const key = `${organizationId}/facilities/${facilityId}/${mediaId}${ext}`;

    const url = await this.storageProvider.upload({
      key,
      buffer: file.buffer,
      mimeType: file.mimetype,
      isPublic: true,
    });

    return this.prisma.media.create({
      data: {
        id: mediaId,
        organizationId,
        facilityId,
        url,
        storageKey: key,
        mimeType: file.mimetype,
        fileSize: file.size,
        type: MediaType.IMAGE,
      },
    });
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

    // 2. Delete from DB
    await this.prisma.media.delete({
      where: { id: mediaId },
    });
  }

  private validateImage(file: any) {
    if (!file) {
      throw new BadRequestException('No file provided');
    }
    if (!this.ALLOWED_IMAGE_MIME_TYPES.includes(file.mimetype)) {
      throw new BadRequestException(`Invalid file type: ${file.mimetype}. Allowed: ${this.ALLOWED_IMAGE_MIME_TYPES.join(', ')}`);
    }
    if (file.size > this.MAX_IMAGE_SIZE) {
      throw new BadRequestException(`File too large: ${file.size}. Max: ${this.MAX_IMAGE_SIZE}`);
    }
  }
}
