import '../../../core/networking/api_client_interface.dart';
import '../domain/models/notification_models.dart';

class NotificationRepository {
  final IApiClient _apiClient;
  final String _organizationId;

  NotificationRepository(this._apiClient, this._organizationId);

  String get _baseUrl => '/organizations/$_organizationId/notifications';

  Future<List<AppNotification>> getNotifications() async {
    final response = await _apiClient.get<List>(_baseUrl);
    if (response.isSuccess) {
      return response.data!.map((n) => AppNotification.fromJson(n)).toList();
    }
    return [];
  }

  Future<void> markAsRead(String id) async {
    await _apiClient.patch('$_baseUrl/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _apiClient.patch('$_baseUrl/read-all');
  }
}
