import { IsNotEmpty, IsDateString, IsOptional, IsInt, Min, Max } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class GetAvailabilityDto {
  @ApiProperty({ example: '2026-08-20', description: 'Date in YYYY-MM-DD format' })
  @IsDateString()
  @IsNotEmpty()
  date: string;

  @ApiPropertyOptional({ example: 60, description: 'Duration in minutes' })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(15)
  @Max(480)
  duration?: number = 60;
}
