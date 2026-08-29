import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';

class AdminAuditLogScreen extends ConsumerWidget {
  const AdminAuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(adminAuditLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Platform Audit Trail')),
      body: logsAsync.when(
        data: (logs) {
          if (logs.isEmpty) return const Center(child: Text('No audit events recorded.'));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final log = logs[index];
              return ListTile(
                title: Text(log.action.replaceAll(':', ' › ').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Actor: ${log.userName ?? "System"}'),
                    if (log.orgName != null) Text('Org: ${log.orgName}'),
                    Text('Resource: ${log.resource} (${log.resourceId})', style: const TextStyle(fontSize: 11)),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(DateFormat('hh:mm a').format(log.createdAt), style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(DateFormat('MMM dd').format(log.createdAt), style: const TextStyle(fontSize: 10)),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading logs: $err')),
      ),
    );
  }
}
