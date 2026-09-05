import { IsString, IsNotEmpty, IsNumber, IsEnum, Min, Max } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export enum MediaCategory {
  VENUE_MEDIA = 'VENUE_MEDIA',
  FACILITY_MEDIA = 'FACILITY_MEDIA',
  KYC_DOCUMENT = 'KYC_DOCUMENT',
}

export enum MediaEntityType {
  VENUE = 'VENUE',
  FACILITY = 'FACILITY',
  ORGANIZATION = 'ORGANIZATION',
  USER = 'USER',
}

export class PresignUploadDto {
  @ApiProperty({ enum: MediaCategory })
  @IsEnum(MediaCategory)
  category: MediaCategory;

  @ApiProperty({ enum: MediaEntityType })
  @IsEnum(MediaEntityType)
  entityType: MediaEntityType;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  entityId: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  filename: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  mimeType: string;

  @ApiProperty({ description: 'File size in bytes' })
  @IsNumber()
  @Min(100)
  @Max(20 * 1024 * 1024) // 20MB max
  fileSize: number;
}
