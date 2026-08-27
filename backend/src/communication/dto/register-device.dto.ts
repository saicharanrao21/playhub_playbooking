import { IsString, IsNotEmpty, IsOptional, IsIn } from 'class-validator';

export class RegisterDeviceDto {
  @IsString()
  @IsNotEmpty()
  token: string;

  @IsString()
  @IsOptional()
  @IsIn(['ios', 'android', 'web'])
  platform?: string;
}
