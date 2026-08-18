import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/notification_repository.dart';
import '../../domain/models/notification_models.dart';
import 'package:playhub_playbooking/app/bootstrap/bootstrap.dart';
import 'package:playhub_playbooking/core/security/auth_provider.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final authState = ref.watch(authStateProvider);
  final orgId = authState.identity?.organizationId ?? '';
  return NotificationRepository(apiClient, orgId);
});

final notificationsProvider = StateNotifierProvider<NotificationNotifier, AsyncValue<List<AppNotification>>>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationNotifier(repository);
});

class NotificationNotifier extends StateNotifier<AsyncValue<List<AppNotification>>> {
  final NotificationRepository _repository;

  NotificationNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = const AsyncValue.loading();
    try {
      final notifications = await _repository.getNotifications();
      state = AsyncValue.data(notifications);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      state.whenData((notifications) {
        state = AsyncValue.data(
          notifications.map((n) => n.id == id ? AppNotification(
            id: n.id,
            organizationId: n.organizationId,
            userId: n.userId,
            bookingId: n.bookingId,
            type: n.type,
            title: n.title,
            message: n.message,
            data: n.data,
            isRead: true,
            readAt: DateTime.now(),
            createdAt: n.createdAt,
          ) : n).toList(),
        );
      });
    } catch (e) {
      // Log error
    }
  }
}
