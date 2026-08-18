import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import '../../domain/models/notification_models.dart';

class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () => ref.read(notificationsProvider.notifier).loadNotifications(), // Should be markAllAsRead
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) => notifications.isEmpty
            ? const Center(child: Text('No notifications yet'))
            : ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return ListTile(
                    leading: _getIcon(notification.type),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(notification.message),
                    trailing: notification.isRead
                        ? null
                        : Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                    onTap: () {
                      if (!notification.isRead) {
                        ref.read(notificationsProvider.notifier).markAsRead(notification.id);
                      }
                    },
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.bookingCreated:
        return const Icon(Icons.add_circle_outline, color: Colors.blue);
      case NotificationType.bookingConfirmed:
        return const Icon(Icons.check_circle, color: Colors.green);
      case NotificationType.bookingCancelled:
        return const Icon(Icons.cancel, color: Colors.red);
      case NotificationType.paymentSuccess:
        return const Icon(Icons.payment, color: Colors.green);
      case NotificationType.paymentFailed:
        return const Icon(Icons.error, color: Colors.red);
      default:
        return const Icon(Icons.notifications);
    }
  }
}
