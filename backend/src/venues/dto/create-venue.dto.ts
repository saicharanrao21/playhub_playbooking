import { IsNotEmpty, IsString, IsOptional, IsNumber, IsEnum, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateVenueDto {
  @ApiProperty({ example: 'Skyline Sports Arena' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  name: string;

  @ApiProperty({ example: 'skyline-arena' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  slug: string;

  @ApiProperty({ example: 'Premium sports facility with multiple courts.' })
  @IsString()
  @IsOptional()
  description?: string;

  @ApiProperty({ example: '123 Main St, Hyderabad' })
  @IsString()
  @IsNotEmpty()
  address: string;

  @ApiProperty({ example: 'Hyderabad' })
  @IsString()
  @IsNotEmpty()
  city: string;

  @ApiProperty({ example: 'Telangana' })
  @IsString()
  @IsNotEmpty()
  state: string;

  @ApiProperty({ example: 'India' })
  @IsString()
  @IsNotEmpty()
  country: string;

  @ApiProperty({ example: '500081' })
  @IsString()
  @IsNotEmpty()
  postalCode: string;

  @ApiProperty({ example: 17.4483 })
  @IsNumber()
  @IsOptional()
  latitude?: number;

  @ApiProperty({ example: 78.3915 })
  @IsNumber()
  @IsOptional()
  longitude?: number;

  @ApiProperty({ example: 'Asia/Kolkata' })
  @IsString()
  @IsOptional()
  timezone?: string;
}
