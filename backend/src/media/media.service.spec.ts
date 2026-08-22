import { Test, TestingModule } from '@nestjs/testing';
import { MediaService } from './media.service';
import { PrismaService } from '../prisma/prisma.service';
import { STORAGE_PROVIDER } from '../common/storage/storage-provider.interface';
import { NotFoundException } from '@nestjs/common';

describe('MediaService', () => {
  let service: MediaService;
  let prisma: PrismaService;
  let storageProvider: any;

  const mockPrisma = {
    venue: { findFirst: jest.fn() },
    facility: { findFirst: jest.fn() },
    media: { create: jest.fn(), findFirst: jest.fn(), delete: jest.fn() },
  };

  const mockStorage = {
    upload: jest.fn(),
    delete: jest.fn(),
    getPublicUrl: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MediaService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: STORAGE_PROVIDER, useValue: mockStorage },
      ],
    }).compile();

    service = module.get<MediaService>(MediaService);
    prisma = module.get<PrismaService>(PrismaService);
    storageProvider = module.get(STORAGE_PROVIDER);
  });

  it('should upload venue image', async () => {
    const file = {
      originalname: 'test.jpg',
      mimetype: 'image/jpeg',
      size: 1000,
      buffer: Buffer.from('test'),
    };
    mockPrisma.venue.findFirst.mockResolvedValue({ id: 'v1' });
    mockStorage.upload.mockResolvedValue('http://url.com');
    mockPrisma.media.create.mockResolvedValue({ id: 'm1', url: 'http://url.com' });

    const result = await service.uploadVenueImage('org1', 'v1', file);
    expect(result.url).toBe('http://url.com');
    expect(mockStorage.upload).toHaveBeenCalled();
    expect(mockPrisma.media.create).toHaveBeenCalled();
  });

  it('should throw NotFoundException if venue not found during upload', async () => {
    mockPrisma.venue.findFirst.mockResolvedValue(null);
    await expect(service.uploadVenueImage('org1', 'v2', {}))
      .rejects.toThrow(NotFoundException);
  });
});
