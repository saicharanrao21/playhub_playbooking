import { IsString, IsOptional, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CancelBookingDto {
  @ApiProperty({ required: false, example: 'User requested' })
  @IsString()
  @IsOptional()
  @MaxLength(255)
  reason?: string;
}
