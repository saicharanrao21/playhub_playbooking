import { Controller, Get, Post, Patch, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { CitiesService } from './cities.service';
import { CreateCityDto } from './dto/create-city.dto';
import { UpdateCityDto } from './dto/update-city.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { Public } from '../common/decorators/public.decorator';

@ApiTags('cities')
@Controller('cities')
export class CitiesController {
  constructor(private readonly citiesService: CitiesService) {}

  @Post()
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @RequirePermission('create:city')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Create a new city (Admin only)' })
  create(@Body() dto: CreateCityDto) {
    return this.citiesService.create(dto);
  }

  @Public()
  @Get()
  @ApiOperation({ summary: 'List all active cities' })
  findAll() {
    return this.citiesService.findAll();
  }

  @Public()
  @Get(':id')
  @ApiOperation({ summary: 'Get city details' })
  findOne(@Param('id') id: string) {
    return this.citiesService.findOne(id);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, PermissionsGuard)
  @RequirePermission('update:city')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Update city details (Admin only)' })
  update(@Param('id') id: string, @Body() dto: UpdateCityDto) {
    return this.citiesService.update(id, dto);
  }
}
