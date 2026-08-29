import { IsString, IsNotEmpty, IsOptional } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class OnboardPartnerDto {
  @ApiProperty({ description: 'The official name of the sports organization / club' })
  @IsString()
  @IsNotEmpty()
  organizationName: string;

  @ApiProperty({ description: 'The registered legal entity name' })
  @IsString()
  @IsNotEmpty()
  legalName: string;

  @ApiProperty({ description: 'Display name visible to customers' })
  @IsString()
  @IsNotEmpty()
  displayName: string;

  @ApiPropertyOptional({ description: 'Business PAN Number' })
  @IsString()
  @IsOptional()
  panNumber?: string;

  @ApiPropertyOptional({ description: 'Business GSTIN' })
  @IsString()
  @IsOptional()
  gstNumber?: string;

  @ApiPropertyOptional({ description: 'Bank Account Holder Name' })
  @IsString()
  @IsOptional()
  accountHolderName?: string;

  @ApiPropertyOptional({ description: 'Bank Account Number' })
  @IsString()
  @IsOptional()
  accountNumber?: string;

  @ApiPropertyOptional({ description: 'Bank IFSC Code' })
  @IsString()
  @IsOptional()
  ifscCode?: string;

  @ApiPropertyOptional({ description: 'Bank Name' })
  @IsString()
  @IsOptional()
  bankName?: string;
}
