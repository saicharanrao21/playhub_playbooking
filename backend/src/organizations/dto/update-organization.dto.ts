import { IsOptional, IsString, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateOrganizationDto {
  @ApiProperty({ required: false })
  @IsString()
  @IsOptional()
  @MaxLength(100)
  name?: string;
}
