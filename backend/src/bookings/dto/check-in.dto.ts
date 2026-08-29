import { IsString, IsNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CheckInDto {
  @ApiProperty()
  @IsString()
  @IsNotEmpty()
  qrToken: string;
}
