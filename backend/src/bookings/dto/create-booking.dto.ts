import { IsNotEmpty, IsDateString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateBookingDto {
  @ApiProperty({ example: '2026-08-20T10:00:00Z' })
  @IsDateString()
  @IsNotEmpty()
  startTime: string;

  @ApiProperty({ example: '2026-08-20T11:00:00Z' })
  @IsDateString()
  @IsNotEmpty()
  endTime: string;
}
