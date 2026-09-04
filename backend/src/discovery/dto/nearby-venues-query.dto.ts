import { IsOptional, IsString, IsNumber, IsUUID, Min, Max, IsEnum } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiPropertyOptional } from '@nestjs/swagger';
import { PaginationDto } from '../../common/dto/pagination.dto';

export enum DiscoverySortBy {
  DISTANCE = 'distance',
  POPULARITY = 'popularity',
  RATING = 'rating',
  PRICE = 'price',
}

export class NearbyVenuesQueryDto extends PaginationDto {
  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude?: number;

  @ApiPropertyOptional({ description: 'Search radius in kilometers (default 10, max 100)' })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0.5)
  @Max(100)
  radius?: number = 10;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  query?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  cityId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  categoryId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  activityId?: string;

  @ApiPropertyOptional({ enum: DiscoverySortBy })
  @IsOptional()
  @IsEnum(DiscoverySortBy)
  sortBy?: DiscoverySortBy = DiscoverySortBy.DISTANCE;
}
