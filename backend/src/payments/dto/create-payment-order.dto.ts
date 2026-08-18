import { IsUUID, IsNotEmpty, IsEnum, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { PaymentProvider } from '@prisma/client';

export class CreatePaymentOrderDto {
  @ApiProperty()
  @IsUUID()
  @IsNotEmpty()
  bookingId: string;

  @ApiProperty({ enum: PaymentProvider, default: PaymentProvider.RAZORPAY })
  @IsEnum(PaymentProvider)
  @IsOptional()
  provider?: PaymentProvider;
}
