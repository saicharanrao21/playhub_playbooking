import '../networking/api_client_interface.dart';
import '../models/app_models.dart';
import 'interfaces.dart';

class DiscoveryRepository implements IDiscoveryRepository {
  final IApiClient _apiClient;

  DiscoveryRepository(this._apiClient);

  @override
  Future<List<Venue>> discoverVenues({
    String? query,
    String? cityId,
    String? categoryId,
    String? activityId,
  }) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/discovery/venues',
      queryParameters: {
        'query': query,
        'cityId': cityId,
        'categoryId': categoryId,
        'activityId': activityId,
      }..removeWhere((k, v) => v == null),
      authenticated: false,
    );

    if (response.isSuccess) {
      final items = response.data!['items'] as List;
      return items.map((e) => Venue.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<List<Venue>> getNearbyVenues({
    double? latitude,
    double? longitude,
    double radius = 10.0,
    String? query,
    String? cityId,
    String? categoryId,
    String? activityId,
    String sortBy = 'distance',
  }) async {
    final Map<String, dynamic> params = {
      'radius': radius.toString(),
      'sortBy': sortBy,
    };
    if (latitude != null) params['latitude'] = latitude.toString();
    if (longitude != null) params['longitude'] = longitude.toString();
    if (query != null && query.isNotEmpty) params['query'] = query;
    if (cityId != null) params['cityId'] = cityId;
    if (categoryId != null) params['categoryId'] = categoryId;
    if (activityId != null) params['activityId'] = activityId;

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/discovery/venues/nearby',
      queryParameters: params,
      authenticated: false,
    );

    if (response.isSuccess && response.data != null) {
      final items = response.data!['items'] as List? ?? [];
      return items.map((e) => Venue.fromJson(e)).toList();
    }
    return [];
  }
}
