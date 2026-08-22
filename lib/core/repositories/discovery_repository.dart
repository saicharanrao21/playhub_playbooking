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
}
