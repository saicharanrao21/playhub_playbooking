import { IsNotEmpty, IsDateString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class RescheduleBookingDto {
  @ApiProperty({ example: '2026-08-21T10:00:00Z' })
  @IsDateString()
  @IsNotEmpty()
  newStartTime: string;

  @ApiProperty({ example: '2026-08-21T11:00:00Z' })
  @IsDateString()
  @IsNotEmpty()
  newEndTime: string;
}
