import '../../../core/networking/api_client_interface.dart';
import '../../../core/repositories/interfaces.dart';
import '../domain/models/venue_models.dart' as domain;
import '../../../core/models/app_models.dart' as core;

class VenueRepository implements IVenueRepository {
  final IApiClient _apiClient;
  final String _organizationId;

  VenueRepository(this._apiClient, this._organizationId);

  String get _baseUrl => '/organizations/$_organizationId/venues';

  @override
  Future<List<core.Venue>> getVenues() async {
    final response = await _apiClient.get<List>(_baseUrl);
    if (response.isSuccess) {
      // We need to map domain.Venue back to core.Venue if the interface strictly requires it
      // or update the interface to use domain models.
      // For now, let's assume we can cast or map.
      return response.data!.map((v) => _toCoreVenue(domain.Venue.fromJson(v))).toList();
    }
    return [];
  }

  @override
  Future<core.Venue?> getVenueById(String id) async {
    final response = await _apiClient.get('$_baseUrl/$id');
    if (response.isSuccess) {
      return _toCoreVenue(domain.Venue.fromJson(response.data));
    }
    return null;
  }

  @override
  Future<List<core.Venue>> searchVenues(String query) async {
    // Backend search not implemented yet, using findAll for now
    return getVenues();
  }

  @override
  Future<List<core.Venue>> getVenuesByCategory(String categoryId) async {
    // Filter locally or implement backend query
    final all = await getVenues();
    return all.where((v) => v.categoryId == categoryId).toList();
  }

  // Helper to map between inconsistent model layers during this transition
  core.Venue _toCoreVenue(domain.Venue v) {
    return core.Venue(
      id: v.id,
      businessId: v.businessId,
      name: v.name,
      description: v.description ?? '',
      address: v.address,
      city: v.city,
      latitude: v.latitude ?? 0.0,
      longitude: v.longitude ?? 0.0,
      imageUrls: [],
      amenities: [],
      rating: 0.0,
      reviewCount: 0,
      categoryId: '',
      facilities: v.facilities?.map((f) => core.Facility(
        id: f.id,
        name: f.name,
        description: f.description,
      )).toList(),
    );
  }

  // Additional method for Phase 22 specific needs if not in interface
  Future<domain.Venue?> getFullVenue(String id) async {
    final response = await _apiClient.get('$_baseUrl/$id');
    if (response.isSuccess) {
      return domain.Venue.fromJson(response.data);
    }
    return null;
  }
}
