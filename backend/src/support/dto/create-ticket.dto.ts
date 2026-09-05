import { IsString, IsNotEmpty, IsOptional, IsEnum } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export enum TicketCategory {
  BOOKING_ISSUE = 'BOOKING_ISSUE',
  PAYMENT_ISSUE = 'PAYMENT_ISSUE',
  REFUND_ISSUE = 'REFUND_ISSUE',
  VENUE_ISSUE = 'VENUE_ISSUE',
  FACILITY_ISSUE = 'FACILITY_ISSUE',
  CANCELLATION_ISSUE = 'CANCELLATION_ISSUE',
  CHECKIN_ISSUE = 'CHECKIN_ISSUE',
  PARTNER_ISSUE = 'PARTNER_ISSUE',
  TECHNICAL_ISSUE = 'TECHNICAL_ISSUE',
  MEMBERSHIP_ISSUE = 'MEMBERSHIP_ISSUE',
  COUPON_ISSUE = 'COUPON_ISSUE',
  LOYALTY_ISSUE = 'LOYALTY_ISSUE',
  OTHER = 'OTHER',
}

export enum TicketPriority {
  LOW = 'LOW',
  MEDIUM = 'MEDIUM',
  HIGH = 'HIGH',
  URGENT = 'URGENT',
}

export class CreateTicketDto {
  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  bookingId?: string;

  @ApiProperty({ enum: TicketCategory })
  @IsEnum(TicketCategory)
  category: TicketCategory;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  subject: string;

  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  description: string;

  @ApiPropertyOptional({ enum: TicketPriority })
  @IsEnum(TicketPriority)
  @IsOptional()
  priority?: TicketPriority;
}
