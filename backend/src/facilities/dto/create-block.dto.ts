import { IsNotEmpty, IsDateString, IsEnum, IsOptional, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { BlockReason } from '@prisma/client';

export class CreateBlockDto {
  @ApiProperty({ example: '2026-08-20T09:00:00Z' })
  @IsDateString()
  @IsNotEmpty()
  startTime: string;

  @ApiProperty({ example: '2026-08-20T11:00:00Z' })
  @IsDateString()
  @IsNotEmpty()
  endTime: string;

  @ApiProperty({ enum: BlockReason })
  @IsEnum(BlockReason)
  @IsNotEmpty()
  reason: BlockReason;

  @ApiProperty({ example: 'Annual maintenance' })
  @IsString()
  @IsOptional()
  notes?: string;
}
