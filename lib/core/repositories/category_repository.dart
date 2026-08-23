import '../networking/api_client_interface.dart';
import '../models/app_models.dart';
import 'interfaces.dart';

class CategoryRepository implements ICategoryRepository {
  final IApiClient _apiClient;

  CategoryRepository(this._apiClient);

  @override
  Future<List<Category>> getCategories() async {
    final response = await _apiClient.get<List>('/categories', authenticated: false);
    if (response.isSuccess) {
      return response.data!.map((e) => Category.fromJson(e)).toList();
    }
    return [];
  }

  @override
  Future<Category?> createCategory(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/categories', data: data);
    if (response.isSuccess) {
      return Category.fromJson(response.data);
    }
    return null;
  }

  @override
  Future<Category?> updateCategory(String id, Map<String, dynamic> data) async {
    final response = await _apiClient.patch('/categories/$id', data: data);
    if (response.isSuccess) {
      return Category.fromJson(response.data);
    }
    return null;
  }
}
