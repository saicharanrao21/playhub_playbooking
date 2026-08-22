import '../networking/api_client_interface.dart';
import '../models/app_models.dart';
import 'dart:io';
import 'package:dio/dio.dart';

class MediaRepository {
  final IApiClient _apiClient;
  final String _organizationId;

  MediaRepository(this._apiClient, this._organizationId);

  String get _baseUrl => '/organizations/$_organizationId/media';

  Future<Media?> uploadVenueImage(String venueId, File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });

    final response = await _apiClient.post(
      '$_baseUrl/venues/$venueId',
      data: formData,
    );

    if (response.isSuccess) {
      return Media.fromJson(response.data);
    }
    return null;
  }

  Future<Media?> uploadFacilityImage(String facilityId, File file) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });

    final response = await _apiClient.post(
      '$_baseUrl/facilities/$facilityId',
      data: formData,
    );

    if (response.isSuccess) {
      return Media.fromJson(response.data);
    }
    return null;
  }

  Future<bool> deleteMedia(String mediaId) async {
    final response = await _apiClient.delete('$_baseUrl/$mediaId');
    return response.isSuccess;
  }
}
