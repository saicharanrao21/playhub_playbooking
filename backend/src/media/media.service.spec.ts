import { Test, TestingModule } from '@nestjs/testing';
import { MediaService } from './media.service';
import { PrismaService } from '../prisma/prisma.service';
import { STORAGE_PROVIDER } from '../common/storage/storage-provider.interface';
import { AuditService } from '../common/services/audit.service';
import { NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { MediaCategory, MediaEntityType } from './dto/presign-upload.dto';

describe('MediaService (Object Storage Pipeline)', () => {
  let service: MediaService;
  let prisma: PrismaService;
  let storageProvider: any;

  const mockPrisma = {
    venue: { findFirst: jest.fn() },
    facility: { findFirst: jest.fn() },
    organization: { findFirst: jest.fn() },
    media: {
      create: jest.fn(),
      findFirst: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
  };

  const mockStorage = {
    upload: jest.fn(),
    delete: jest.fn(),
    getPublicUrl: jest.fn().mockReturnValue('https://cdn.playhub.app/key.jpg'),
    createPresignedUpload: jest.fn().mockResolvedValue({
      uploadUrl: 'https://s3.amazonaws.com/presigned_url',
      expiresAt: new Date(),
    }),
    createPresignedDownload: jest.fn().mockResolvedValue({
      downloadUrl: 'https://s3.amazonaws.com/private_download_url',
      expiresAt: new Date(),
    }),
    headObject: jest.fn().mockResolvedValue({ exists: true, contentLength: 5000 }),
  };

  const mockAuditService = {
    record: jest.fn().mockResolvedValue({}),
  };

  beforeEach(async () => {
    jest.clearAllMocks();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MediaService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: STORAGE_PROVIDER, useValue: mockStorage },
        { provide: AuditService, useValue: mockAuditService },
      ],
    }).compile();

    service = module.get<MediaService>(MediaService);
    prisma = module.get<PrismaService>(PrismaService);
    storageProvider = module.get(STORAGE_PROVIDER);
  });

  it('should request presigned upload URL for valid venue media', async () => {
    mockPrisma.venue.findFirst.mockResolvedValue({ id: 'venue-101' });
    mockPrisma.media.create.mockResolvedValue({ id: 'media-101', storageKey: 'key.jpg' });

    const result = await service.requestPresignedUpload('org-101', 'user-101', {
      category: MediaCategory.VENUE_MEDIA,
      entityType: MediaEntityType.VENUE,
      entityId: 'venue-101',
      filename: 'court.jpg',
      mimeType: 'image/jpeg',
      fileSize: 1024 * 500,
    });

    expect(result.uploadUrl).toBeDefined();
    expect(result.mediaId).toBe('media-101');
    expect(mockStorage.createPresignedUpload).toHaveBeenCalled();
    expect(mockPrisma.media.create).toHaveBeenCalled();
  });

  it('should reject invalid MIME type for venue media', async () => {
    await expect(
      service.requestPresignedUpload('org-101', 'user-101', {
        category: MediaCategory.VENUE_MEDIA,
        entityType: MediaEntityType.VENUE,
        entityId: 'venue-101',
        filename: 'script.exe',
        mimeType: 'application/x-msdownload',
        fileSize: 1024,
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('should complete media upload after object exists in storage', async () => {
    mockPrisma.media.findFirst.mockResolvedValue({
      id: 'media-101',
      organizationId: 'org-101',
      storageKey: 'key.jpg',
      visibility: 'PUBLIC',
      type: 'IMAGE',
    });
    mockPrisma.media.update.mockResolvedValue({ id: 'media-101', status: 'READY' });

    const result = await service.completeUpload('org-101', 'media-101');
    expect(result.status).toBe('READY');
    expect(mockStorage.headObject).toHaveBeenCalledWith('key.jpg');
    expect(mockPrisma.media.update).toHaveBeenCalledWith(
      expect.objectContaining({ where: { id: 'media-101' }, data: expect.objectContaining({ status: 'READY' }) }),
    );
  });

  it('should issue short-lived download URL for authorized private KYC documents', async () => {
    mockPrisma.media.findUnique.mockResolvedValue({
      id: 'kyc-101',
      organizationId: 'org-101',
      storageKey: 'kyc_pan.pdf',
      visibility: 'PRIVATE',
    });

    const result = await service.getPrivateDownloadUrl('org-101', 'kyc-101');
    expect(result.downloadUrl).toContain('private_download_url');
    expect(mockStorage.createPresignedDownload).toHaveBeenCalledWith(
      expect.objectContaining({ key: 'kyc_pan.pdf' }),
    );
  });

  it('should throw ForbiddenException if partner queries another organization private KYC', async () => {
    mockPrisma.media.findUnique.mockResolvedValue({
      id: 'kyc-101',
      organizationId: 'org-OTHER',
      visibility: 'PRIVATE',
    });

    await expect(service.getPrivateDownloadUrl('org-101', 'kyc-101')).rejects.toThrow(ForbiddenException);
  });
});
