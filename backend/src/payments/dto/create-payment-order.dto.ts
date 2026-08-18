import { IsUUID, IsNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreatePaymentOrderDto {
  @ApiProperty()
  @IsUUID()
  @IsNotEmpty()
  bookingId: string;
}
