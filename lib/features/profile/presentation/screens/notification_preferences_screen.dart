import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/repositories/communication_repository.dart';
import '../../../../shared/components/error_view.dart';

final notificationPreferencesProvider = StateNotifierProvider.autoDispose<
    NotificationPreferencesNotifier,
    AsyncValue<List<CommunicationPreference>>>((ref) {
  final repo = ref.watch(communicationRepositoryProvider);
  return NotificationPreferencesNotifier(repo);
});

class NotificationPreferencesNotifier
    extends StateNotifier<AsyncValue<List<CommunicationPreference>>> {
  final CommunicationRepository _repo;

  NotificationPreferencesNotifier(this._repo) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final prefs = await _repo.getPreferences();
      state = AsyncValue.data(prefs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> togglePreference(
    CommunicationCategory category,
    CommunicationChannel channel,
    bool isEnabled,
  ) async {
    try {
      await _repo.updatePreference(category, channel, isEnabled);
      final current = state.value ?? [];
      final index = current.indexWhere(
        (p) => p.category == category && p.channel == channel,
      );

      if (index != -1) {
        final updatedList = List<CommunicationPreference>.from(current);
        updatedList[index] = CommunicationPreference(
          category: category,
          channel: channel,
          isEnabled: isEnabled,
        );
        state = AsyncValue.data(updatedList);
      } else {
        state = AsyncValue.data([
          ...current,
          CommunicationPreference(
            category: category,
            channel: channel,
            isEnabled: isEnabled,
          )
        ]);
      }
    } catch (e) {
      debugPrint('Failed to update preference: $e');
    }
  }
}

class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Preferences', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: prefsAsync.when(
        data: (prefs) => _buildList(context, ref, prefs),
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        error: (e, _) => AppErrorView(
          message: 'Failed to load preferences: $e',
          onRetry: () => ref.read(notificationPreferencesProvider.notifier).load(),
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<CommunicationPreference> prefs,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(context, 'Transactional Alerts (Bookings & Payments)'),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              _buildPreferenceTile(
                ref,
                prefs,
                CommunicationCategory.transactional,
                CommunicationChannel.push,
                'Push Notifications',
                'Instant booking confirmations and slot reminders',
                Icons.notifications_active_outlined,
              ),
              const Divider(height: 1),
              _buildPreferenceTile(
                ref,
                prefs,
                CommunicationCategory.transactional,
                CommunicationChannel.email,
                'Email Receipts',
                'Invoices and booking pass PDFs',
                Icons.email_outlined,
              ),
              const Divider(height: 1),
              _buildPreferenceTile(
                ref,
                prefs,
                CommunicationCategory.transactional,
                CommunicationChannel.sms,
                'SMS Alerts',
                'Time-critical venue access pins',
                Icons.sms_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionHeader(context, 'Marketing, Matches & Community'),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              _buildPreferenceTile(
                ref,
                prefs,
                CommunicationCategory.marketing,
                CommunicationChannel.push,
                'Match Invitations & Community Posts',
                'When players in your city host new sports matches',
                Icons.sports_soccer_outlined,
              ),
              const Divider(height: 1),
              _buildPreferenceTile(
                ref,
                prefs,
                CommunicationCategory.marketing,
                CommunicationChannel.email,
                'Promotions & Discounts',
                'Weekly offers and tournament news',
                Icons.local_offer_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildPreferenceTile(
    WidgetRef ref,
    List<CommunicationPreference> prefs,
    CommunicationCategory category,
    CommunicationChannel channel,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isEnabled = prefs.any(
      (p) => p.category == category && p.channel == channel && p.isEnabled,
    );

    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: isEnabled,
      onChanged: (value) {
        ref
            .read(notificationPreferencesProvider.notifier)
            .togglePreference(category, channel, value);
      },
    );
  }
}
