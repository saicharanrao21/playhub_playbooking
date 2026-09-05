import { IsString, IsNotEmpty, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export enum DisputeReason {
  VENUE_UNAVAILABLE = 'VENUE_UNAVAILABLE',
  VENUE_CLOSED = 'VENUE_CLOSED',
  FACILITY_UNAVAILABLE = 'FACILITY_UNAVAILABLE',
  BOOKING_NOT_HONORED = 'BOOKING_NOT_HONORED',
  INCORRECT_CHARGE = 'INCORRECT_CHARGE',
  DUPLICATE_CHARGE = 'DUPLICATE_CHARGE',
  CHECKIN_FAILURE = 'CHECKIN_FAILURE',
  SERVICE_QUALITY = 'SERVICE_QUALITY',
  OTHER = 'OTHER',
}

export class CreateDisputeDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  bookingId: string;

  @ApiProperty({ enum: DisputeReason })
  @IsEnum(DisputeReason)
  reason: DisputeReason;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  description: string;
}
