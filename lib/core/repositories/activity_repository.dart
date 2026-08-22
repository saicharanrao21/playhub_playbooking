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
}
