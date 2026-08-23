import '../networking/api_client_interface.dart';
import '../models/app_models.dart';
import 'interfaces.dart';

class ActivityRepository implements IActivityRepository {
  final IApiClient _apiClient;

  ActivityRepository(this._apiClient);

  @override
  Future<List<Activity>> getActivities({String? categoryId}) async {
    final response = await _apiClient.get<List>(
      '/activities',
      queryParameters: categoryId != null ? {'categoryId': categoryId} : null,
      authenticated: false,
    );
    if (response.isSuccess) {
      return response.data!.map((e) => Activity.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<Activity?> createActivity(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/activities', data: data);
    if (response.isSuccess) {
      return Activity.fromJson(response.data);
    }
    return null;
  }

  @override
  Future<Activity?> updateActivity(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.patch('/activities/$id', data: data);
    if (response.isSuccess) {
      return Activity.fromJson(response.data);
    }
    return null;
  }
}
