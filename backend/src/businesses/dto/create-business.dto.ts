import { IsNotEmpty, IsString, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateBusinessDto {
  @ApiProperty({ example: 'PlayHub Arena Pvt Ltd' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  legalName: string;

  @ApiProperty({ example: 'Skyline Arena' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  displayName: string;
}
