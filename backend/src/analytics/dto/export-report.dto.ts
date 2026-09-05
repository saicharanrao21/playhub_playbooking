import { IsString, IsNotEmpty, IsEnum, IsOptional, IsDateString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { DatePreset } from './analytics-filter.dto';

export enum ReportType {
  BOOKINGS = 'BOOKINGS',
  REVENUE = 'REVENUE',
  PAYOUTS = 'PAYOUTS',
  VENUE_PERFORMANCE = 'VENUE_PERFORMANCE',
  PEAK_TIMES = 'PEAK_TIMES',
}

export enum ExportFormat {
  CSV = 'CSV',
  PDF = 'PDF',
}

export class ExportReportDto {
  @ApiProperty({ enum: ReportType })
  @IsEnum(ReportType)
  reportType: ReportType;

  @ApiProperty({ enum: ExportFormat })
  @IsEnum(ExportFormat)
  format: ExportFormat;

  @ApiPropertyOptional({ enum: DatePreset })
  @IsEnum(DatePreset)
  @IsOptional()
  preset?: DatePreset = DatePreset.LAST_30_DAYS;

  @ApiPropertyOptional()
  @IsDateString()
  @IsOptional()
  startDate?: string;

  @ApiPropertyOptional()
  @IsDateString()
  @IsOptional()
  endDate?: string;
}
