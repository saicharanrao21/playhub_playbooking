import { IsNotEmpty, IsString, IsOptional, IsInt, Min, Max, MaxLength } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateFacilityDto {
  @ApiProperty({ example: 'Football Turf 1' })
  @IsString()
  @IsNotEmpty()
  @MaxLength(100)
  name: string;

  @ApiProperty({ example: 'Full size 5-a-side football turf.' })
  @IsString()
  @IsOptional()
  @MaxLength(500)
  description?: string;

  @ApiProperty({ example: 'category-id' })
  @IsString()
  @IsNotEmpty()
  categoryId: string;

  @ApiProperty({ example: 10 })
  @IsInt()
  @Min(1)
  @Max(1000)
  @IsOptional()
  capacity?: number;
}
