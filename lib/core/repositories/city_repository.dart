import '../networking/api_client_interface.dart';
import '../models/app_models.dart';
import 'interfaces.dart';

class CityRepository implements ICityRepository {
  final IApiClient _apiClient;

  CityRepository(this._apiClient);

  @override
  Future<List<City>> getCities() async {
    final response = await _apiClient.get<List>('/cities', authenticated: false);
    if (response.isSuccess) {
      return response.data!.map((e) => City.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<City?> createCity(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/cities', data: data);
    if (response.isSuccess) {
      return City.fromJson(response.data);
    }
    return null;
  }

  @override
  Future<City?> updateCity(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.patch('/cities/$id', data: data);
    if (response.isSuccess) {
      return City.fromJson(response.data);
    }
    return null;
  }
}
