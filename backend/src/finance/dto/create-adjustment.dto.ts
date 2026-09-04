import { IsString, IsNotEmpty, IsNumber, IsEnum, Min } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export enum AdjustmentDirection {
  CREDIT = 'CREDIT', // Goodwill/bonus to partner (increases PARTNER_PAYABLE)
  DEBIT = 'DEBIT',   // Penalty/deduction from partner (decreases PARTNER_PAYABLE)
}

export class CreateAdjustmentDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  organizationId: string;

  @ApiProperty()
  @IsNumber()
  @Min(0.01)
  amount: number;

  @ApiProperty({ enum: AdjustmentDirection })
  @IsEnum(AdjustmentDirection)
  direction: AdjustmentDirection;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  reason: string;
}
