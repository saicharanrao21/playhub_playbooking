import { PartialType } from '@nestjs/swagger';
import { CreateBusinessDto } from './create-business.dto';
import { IsEnum, IsOptional } from 'class-validator';
import { BusinessStatus } from '@prisma/client';

export class UpdateBusinessDto extends PartialType(CreateBusinessDto) {
  @IsEnum(BusinessStatus)
  @IsOptional()
  status?: BusinessStatus;
}
