import { Controller, Post, Delete, Param, UseInterceptors, UploadedFile, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiConsumes, ApiBody } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { MediaService } from './media.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OrganizationGuard } from '../common/guards/organization.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { Permissions } from '../common/constants/permissions';
import { OrganizationContext } from '../common/decorators/organization-context.decorator';

@ApiTags('media')
@Controller('organizations/:organizationId/media')
@UseGuards(JwtAuthGuard, OrganizationGuard, PermissionsGuard)
@ApiBearerAuth()
export class MediaController {
  constructor(private readonly mediaService: MediaService) {}

  @Post('venues/:venueId')
  @RequirePermission(Permissions.VENUE_UPDATE)
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: { type: 'string', format: 'binary' },
      },
    },
  })
  @ApiOperation({ summary: 'Upload an image for a venue' })
  uploadVenueImage(
    @OrganizationContext() organizationId: string,
    @Param('venueId') venueId: string,
    @UploadedFile() file: any,
  ) {
    return this.mediaService.uploadVenueImage(organizationId, venueId, file);
  }

  @Post('facilities/:facilityId')
  @RequirePermission(Permissions.FACILITY_UPDATE)
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        file: { type: 'string', format: 'binary' },
      },
    },
  })
  @ApiOperation({ summary: 'Upload an image for a facility' })
  uploadFacilityImage(
    @OrganizationContext() organizationId: string,
    @Param('facilityId') facilityId: string,
    @UploadedFile() file: any,
  ) {
    return this.mediaService.uploadFacilityImage(organizationId, facilityId, file);
  }

  @Delete(':id')
  @RequirePermission(Permissions.VENUE_UPDATE) // Assuming venue update permission allows media deletion in that org
  @ApiOperation({ summary: 'Delete a media object' })
  deleteMedia(
    @OrganizationContext() organizationId: string,
    @Param('id') id: string,
  ) {
    return this.mediaService.deleteMedia(organizationId, id);
  }
}
