import '../../../core/networking/api_client_interface.dart';
import '../domain/models/availability_models.dart';

class AvailabilityRepository {
  final IApiClient _apiClient;
  final String _organizationId;

  AvailabilityRepository(this._apiClient, this._organizationId);

  Future<Availability?> getAvailability({
    required String facilityId,
    required String date, // YYYY-MM-DD
    int durationMinutes = 60,
  }) async {
    final response = await _apiClient.get(
      '/organizations/$_organizationId/availability/facilities/$facilityId',
      queryParameters: {
        'date': date,
        'duration': durationMinutes.toString(),
      },
    );

    if (response.isSuccess) {
      return Availability.fromJson(response.data);
    }
    return null;
  }
}
