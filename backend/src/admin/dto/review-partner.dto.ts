import { IsEnum, IsString, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { KYCStatus } from '@prisma/client';

export class ReviewPartnerDto {
  @ApiProperty({ enum: KYCStatus })
  @IsEnum(KYCStatus)
  kycStatus: KYCStatus;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  reason?: string;
}
