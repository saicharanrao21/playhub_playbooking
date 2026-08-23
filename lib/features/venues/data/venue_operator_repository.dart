import '../../../core/networking/api_client_interface.dart';
import '../domain/models/venue_models.dart';

class VenueOperatorRepository {
  final IApiClient _apiClient;
  final String _organizationId;

  VenueOperatorRepository(this._apiClient, this._organizationId);

  String get _baseUrl => '/organizations/$_organizationId';

  Future<List<Business>> getBusinesses() async {
    final response = await _apiClient.get<List>('$_baseUrl/businesses');
    if (response.isSuccess) {
      return response.data!.map((b) => Business.fromJson(b)).toList();
    }
    return [];
  }

  Future<List<Venue>> getVenues({String? businessId}) async {
    final response = await _apiClient.get<List>(
      '$_baseUrl/venues',
      queryParameters: businessId != null ? {'businessId': businessId} : null,
    );
    if (response.isSuccess) {
      return response.data!.map((v) => Venue.fromJson(v)).toList();
    }
    return [];
  }

  Future<Venue?> getVenue(String id) async {
    final response = await _apiClient.get('$_baseUrl/venues/$id');
    if (response.isSuccess) {
      return Venue.fromJson(response.data);
    }
    return null;
  }

  Future<void> updateVenue(String id, Map<String, dynamic> data) async {
    await _apiClient.patch('$_baseUrl/venues/$id', data: data);
  }

  Future<void> updateOperatingHours(String venueId, List<Map<String, dynamic>> hours) async {
    await _apiClient.patch('$_baseUrl/venues/$venueId/operating-hours', data: hours);
  }

  Future<List<Facility>> getFacilities(String venueId) async {
    final response = await _apiClient.get<List>(
      '$_baseUrl/venues/$venueId/facilities', // Consistent with standard routing
    );
    if (response.isSuccess) {
      return response.data!.map((f) => Facility.fromJson(f)).toList();
    }
    return [];
  }

  Future<Facility?> getFacility(String venueId, String facilityId) async {
    final response = await _apiClient.get('$_baseUrl/venues/$venueId/facilities/$facilityId');
    if (response.isSuccess) {
      return Facility.fromJson(response.data);
    }
    return null;
  }
}
