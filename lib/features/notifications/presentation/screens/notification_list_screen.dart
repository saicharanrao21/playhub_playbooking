import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:playhub_playbooking/features/notifications/presentation/providers/notification_provider.dart';
import 'package:playhub_playbooking/features/notifications/domain/models/notification_models.dart';
import 'package:playhub_playbooking/shared/components/empty_view.dart';
import 'package:playhub_playbooking/shared/components/error_view.dart';
import 'package:playhub_playbooking/shared/components/loading_indicator.dart';

class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: () {
              final list = notificationsAsync.value ?? [];
              for (final n in list) {
                if (!n.isRead) {
                  ref.read(notificationsProvider.notifier).markAsRead(n.id);
                }
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications marked as read.')),
              );
            },
            tooltip: 'Mark All as Read',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(notificationsProvider.notifier).loadNotifications(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(notificationsProvider.notifier).loadNotifications();
        },
        child: notificationsAsync.when(
          data: (notifications) {
            if (notifications.isEmpty) {
              return const EmptyView(
                icon: Icons.notifications_off_outlined,
                title: 'No notifications',
                message: 'You have no new alerts. Updates regarding your bookings and matches will appear here.',
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (c, i) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final iconData = _getIconData(notification.type);
                final iconColor = _getIconColor(notification.type);

                return ListTile(
                  tileColor: notification.isRead ? null : colorScheme.primaryContainer.withValues(alpha: 0.12),
                  leading: CircleAvatar(
                    backgroundColor: iconColor.withValues(alpha: 0.15),
                    child: Icon(iconData, color: iconColor, size: 22),
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM d • h:mm a').format(notification.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  trailing: notification.isRead
                      ? null
                      : Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
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
            );
          },
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 5,
            itemBuilder: (c, i) => const SkeletonCard(height: 75),
          ),
          error: (err, stack) => AppErrorView(
            message: 'Failed to load notifications: $err',
            onRetry: () => ref.read(notificationsProvider.notifier).loadNotifications(),
          ),
        ),
      ),
    );
  }

  IconData _getIconData(NotificationType type) {
    switch (type) {
      case NotificationType.bookingCreated:
        return Icons.event_available;
      case NotificationType.bookingConfirmed:
        return Icons.check_circle_outline;
      case NotificationType.bookingCancelled:
        return Icons.cancel_outlined;
      case NotificationType.paymentSuccess:
        return Icons.payments_outlined;
      case NotificationType.paymentFailed:
        return Icons.error_outline;
      default:
        return Icons.notifications_none;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.bookingConfirmed:
      case NotificationType.paymentSuccess:
        return Colors.green;
      case NotificationType.bookingCancelled:
      case NotificationType.paymentFailed:
        return Colors.red;
      case NotificationType.bookingCreated:
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }
}
