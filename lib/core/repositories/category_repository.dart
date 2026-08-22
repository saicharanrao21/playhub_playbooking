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
}
