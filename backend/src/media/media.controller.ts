import {
  Controller,
  Post,
  Get,
  Delete,
  Param,
  Body,
  UseGuards,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiConsumes, ApiHeader } from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { MediaService } from './media.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { OrganizationGuard } from '../common/guards/organization.guard';
import { PermissionsGuard } from '../common/guards/permissions.guard';
import { RequirePermission } from '../common/decorators/require-permission.decorator';
import { Permissions } from '../common/constants/permissions';
import { OrganizationContext } from '../common/decorators/organization-context.decorator';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UserIdentity } from '../common/interfaces/user-identity.interface';
import { PresignUploadDto } from './dto/presign-upload.dto';

@ApiTags('media')
@Controller('organizations/:organizationId')
@UseGuards(JwtAuthGuard, OrganizationGuard, PermissionsGuard)
@ApiBearerAuth()
@ApiHeader({ name: 'x-organization-id', required: true })
export class MediaController {
  constructor(private readonly mediaService: MediaService) {}

  @Post('media/presign')
  @RequirePermission(Permissions.VENUE_UPDATE)
  @ApiOperation({ summary: 'Request presigned upload URL for S3/R2 object storage' })
  async requestPresignedUpload(
    @OrganizationContext() organizationId: string,
    @CurrentUser() user: UserIdentity,
    @Body() dto: PresignUploadDto,
  ) {
    return this.mediaService.requestPresignedUpload(organizationId, user.userId, dto);
  }

  @Post('media/:id/complete')
  @RequirePermission(Permissions.VENUE_UPDATE)
  @ApiOperation({ summary: 'Complete media upload after direct binary upload to storage' })
  async completeUpload(
    @OrganizationContext() organizationId: string,
    @Param('id') mediaId: string,
  ) {
    return this.mediaService.completeUpload(organizationId, mediaId);
  }

  @Get('media/:id/download')
  @RequirePermission(Permissions.ORGANIZATION_READ)
  @ApiOperation({ summary: 'Get short-lived presigned download URL for private KYC documents' })
  async getPrivateDownloadUrl(
    @OrganizationContext() organizationId: string,
    @Param('id') mediaId: string,
  ) {
    return this.mediaService.getPrivateDownloadUrl(organizationId, mediaId);
  }

  @Delete('media/:id')
  @RequirePermission(Permissions.VENUE_UPDATE)
  @ApiOperation({ summary: 'Delete media asset from database and object storage' })
  async deleteMedia(
    @OrganizationContext() organizationId: string,
    @Param('id') mediaId: string,
  ) {
    return this.mediaService.deleteMedia(organizationId, mediaId);
  }

  @Post('venues/:venueId/images')
  @RequirePermission(Permissions.VENUE_UPDATE)
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Legacy: Upload venue gallery image' })
  async uploadVenueImage(
    @OrganizationContext() organizationId: string,
    @Param('venueId') venueId: string,
    @UploadedFile() file: any,
  ) {
    return this.mediaService.uploadVenueImage(organizationId, venueId, file);
  }

  @Post('facilities/:facilityId/images')
  @RequirePermission(Permissions.VENUE_UPDATE)
  @UseInterceptors(FileInterceptor('file'))
  @ApiConsumes('multipart/form-data')
  @ApiOperation({ summary: 'Legacy: Upload facility gallery image' })
  async uploadFacilityImage(
    @OrganizationContext() organizationId: string,
    @Param('facilityId') facilityId: string,
    @UploadedFile() file: any,
  ) {
    return this.mediaService.uploadFacilityImage(organizationId, facilityId, file);
  }
}
