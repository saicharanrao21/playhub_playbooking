import { PartialType } from '@nestjs/swagger';
import { CreateVenueDto } from './create-venue.dto';
import { IsEnum, IsOptional } from 'class-validator';
import { VenueStatus } from '@prisma/client';

export class UpdateVenueDto extends PartialType(CreateVenueDto) {
  @IsEnum(VenueStatus)
  @IsOptional()
  status?: VenueStatus;
}
