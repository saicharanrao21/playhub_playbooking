import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_finance_provider.dart';
import '../../../../app/bootstrap/bootstrap.dart';

class AdminCommissionConfigScreen extends ConsumerStatefulWidget {
  const AdminCommissionConfigScreen({super.key});

  @override
  ConsumerState<AdminCommissionConfigScreen> createState() => _AdminCommissionConfigScreenState();
}

class _AdminCommissionConfigScreenState extends ConsumerState<AdminCommissionConfigScreen> {
  Future<void> _showAddConfigDialog() async {
    final nameController = TextEditingController(text: 'Standard Commission');
    final pctController = TextEditingController(text: '10.0');
    final orgIdController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Commission Rule'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Rule Name')),
            const SizedBox(height: 10),
            TextField(controller: pctController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Percentage (%)')),
            const SizedBox(height: 10),
            TextField(controller: orgIdController, decoration: const InputDecoration(labelText: 'Org ID (Optional - Blank for Global)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Save Rule')),
        ],
      ),
    );

    if (confirmed == true) {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post(
        '/admin/finance/commissions',
        data: {
          'name': nameController.text.trim(),
          'percentage': double.tryParse(pctController.text) ?? 10.0,
          if (orgIdController.text.trim().isNotEmpty) 'organizationId': orgIdController.text.trim(),
        },
      );

      if (mounted) {
        if (response.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Commission rule saved!'), backgroundColor: Colors.green));
          ref.invalidate(adminCommissionsProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save rule'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final configsAsync = ref.watch(adminCommissionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Commission Governance')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddConfigDialog,
        icon: const Icon(Icons.add),
        label: const Text('New Rule'),
      ),
      body: configsAsync.when(
        data: (configs) {
          if (configs.isEmpty) return const Center(child: Text('No commission rules configured.'));

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: configs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final c = configs[index] as Map<String, dynamic>;
              final isGlobal = c['organizationId'] == null;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isGlobal ? Colors.blue.withValues(alpha: 0.15) : Colors.purple.withValues(alpha: 0.15),
                    child: Icon(isGlobal ? Icons.public : Icons.business, color: isGlobal ? Colors.blue : Colors.purple, size: 20),
                  ),
                  title: Text(c['name'] ?? 'Commission Rule', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(isGlobal ? 'Global Platform Default' : 'Org: ${c['organization']?['name'] ?? c['organizationId']}'),
                  trailing: Text('${c['percentage']}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
