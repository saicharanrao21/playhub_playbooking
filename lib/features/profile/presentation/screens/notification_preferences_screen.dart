import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/repositories/communication_repository.dart';

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
      // Optimistic update
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
      appBar: AppBar(title: const Text('Notification Preferences')),
      body: prefsAsync.when(
        data: (prefs) => _buildList(context, ref, prefs),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<CommunicationPreference> prefs,
  ) {
    return ListView(
      children: [
        _buildSectionHeader('Transactional Notifications'),
        _buildPreferenceTile(
          ref,
          prefs,
          CommunicationCategory.transactional,
          CommunicationChannel.email,
          'Email',
          Icons.email,
        ),
        _buildPreferenceTile(
          ref,
          prefs,
          CommunicationCategory.transactional,
          CommunicationChannel.sms,
          'SMS',
          Icons.sms,
        ),
        _buildPreferenceTile(
          ref,
          prefs,
          CommunicationCategory.transactional,
          CommunicationChannel.push,
          'Push Notifications',
          Icons.notifications_active,
        ),
        const Divider(),
        _buildSectionHeader('Marketing & Updates'),
        _buildPreferenceTile(
          ref,
          prefs,
          CommunicationCategory.marketing,
          CommunicationChannel.email,
          'Email',
          Icons.email,
        ),
        _buildPreferenceTile(
          ref,
          prefs,
          CommunicationCategory.marketing,
          CommunicationChannel.push,
          'Push Notifications',
          Icons.notifications_active,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
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
    IconData icon,
  ) {
    final isEnabled = prefs.any(
      (p) => p.category == category && p.channel == channel && p.isEnabled,
    );

    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Switch(
        value: isEnabled,
        onChanged: (value) {
          ref
              .read(notificationPreferencesProvider.notifier)
              .togglePreference(category, channel, value);
        },
      ),
    );
  }
}
