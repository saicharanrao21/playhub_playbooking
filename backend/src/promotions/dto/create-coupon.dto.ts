import { IsString, IsNotEmpty, IsNumber, IsOptional, IsBoolean, IsDateString, Min, Max, IsEnum } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum CouponDiscountType {
  PERCENTAGE = 'PERCENTAGE',
  FIXED = 'FIXED',
}

export class CreateCouponDto {
  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  organizationId?: string; // Null for global platform coupons

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  code: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  description?: string;

  @ApiProperty({ enum: CouponDiscountType })
  @IsEnum(CouponDiscountType)
  discountType: CouponDiscountType;

  @ApiProperty()
  @IsNumber()
  @Min(0.01)
  discountValue: number;

  @ApiPropertyOptional()
  @IsNumber()
  @Min(0)
  @IsOptional()
  minBookingAmount?: number;

  @ApiPropertyOptional()
  @IsNumber()
  @Min(0)
  @IsOptional()
  maxDiscountAmount?: number;

  @ApiPropertyOptional()
  @IsDateString()
  @IsOptional()
  validFrom?: string;

  @ApiPropertyOptional()
  @IsDateString()
  @IsOptional()
  validTo?: string;

  @ApiPropertyOptional()
  @IsNumber()
  @IsOptional()
  totalRedemptionLimit?: number;

  @ApiPropertyOptional()
  @IsNumber()
  @IsOptional()
  perUserRedemptionLimit?: number;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  firstBookingOnly?: boolean;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  membershipRequired?: boolean;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  venueId?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  facilityId?: string;

  @ApiPropertyOptional()
  @IsBoolean()
  @IsOptional()
  isActive?: boolean;
}
