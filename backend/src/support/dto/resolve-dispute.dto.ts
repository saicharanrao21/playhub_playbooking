import { IsString, IsNotEmpty, IsEnum, IsNumber, IsOptional, Min } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum DisputeDecision {
  FULL_REFUND = 'FULL_REFUND',
  PARTIAL_REFUND = 'PARTIAL_REFUND',
  NO_REFUND = 'NO_REFUND',
  GOODWILL_CREDIT = 'GOODWILL_CREDIT',
}

export class ResolveDisputeDto {
  @ApiProperty({ enum: DisputeDecision })
  @IsEnum(DisputeDecision)
  decision: DisputeDecision;

  @ApiPropertyOptional()
  @IsNumber()
  @Min(0)
  @IsOptional()
  refundAmount?: number;

  @ApiPropertyOptional()
  @IsNumber()
  @Min(0)
  @IsOptional()
  goodwillPoints?: number;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  resolutionNotes: string;
}
