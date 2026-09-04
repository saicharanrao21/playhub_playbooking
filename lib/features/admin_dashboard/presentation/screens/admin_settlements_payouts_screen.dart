import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/admin_finance_provider.dart';
import '../../../../app/bootstrap/bootstrap.dart';

class AdminSettlementsPayoutsScreen extends ConsumerStatefulWidget {
  const AdminSettlementsPayoutsScreen({super.key});

  @override
  ConsumerState<AdminSettlementsPayoutsScreen> createState() => _AdminSettlementsPayoutsScreenState();
}

class _AdminSettlementsPayoutsScreenState extends ConsumerState<AdminSettlementsPayoutsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _completePayout(String payoutId) async {
    final refController = TextEditingController(text: 'BANK_REF_${DateTime.now().millisecondsSinceEpoch}');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Payout'),
        content: TextField(
          controller: refController,
          decoration: const InputDecoration(labelText: 'Bank Reference / UTR Number'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirm Complete')),
        ],
      ),
    );

    if (confirmed == true) {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post(
        '/admin/finance/payouts/$payoutId/complete',
        data: {'providerReference': refController.text.trim()},
      );

      if (mounted) {
        if (response.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout marked COMPLETED!'), backgroundColor: Colors.green));
          ref.invalidate(adminPayoutsProvider);
          ref.invalidate(adminFinanceOverviewProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to complete payout'), backgroundColor: Colors.red));
        }
      }
    }
  }

  Future<void> _failPayout(String payoutId) async {
    final reasonController = TextEditingController(text: 'Bank account number invalid / returned');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fail Payout & Restore Partner Balance'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Failure Reason'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Fail & Restore Balance'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post(
        '/admin/finance/payouts/$payoutId/fail',
        data: {'reason': reasonController.text.trim()},
      );

      if (mounted) {
        if (response.isSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout set to FAILED and balance restored.'), backgroundColor: Colors.orange));
          ref.invalidate(adminPayoutsProvider);
          ref.invalidate(adminFinanceOverviewProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to mark payout failed'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settlementsAsync = ref.watch(adminSettlementsProvider);
    final payoutsAsync = ref.watch(adminPayoutsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settlements & Payout Operations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Payout Queue'),
            Tab(text: 'Settlement History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Payout Queue Tab
          payoutsAsync.when(
            data: (payouts) {
              if (payouts.isEmpty) return const Center(child: Text('No payouts in queue.'));

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: payouts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final p = payouts[index] as Map<String, dynamic>;
                  final status = p['status'] ?? 'PENDING';
                  final isProcessing = status == 'PROCESSING' || status == 'PENDING';

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Payout #${p['id'].toString().substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text('₹${(p['amount'] ?? 0).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('Org: ${p['organization']?['name'] ?? p['organizationId']}'),
                          Text('Status: $status • ${DateFormat('MMM dd, yyyy').format(DateTime.parse(p['createdAt']))}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          if (p['failureReason'] != null)
                            Text('Failure Reason: ${p['failureReason']}', style: const TextStyle(fontSize: 11, color: Colors.red)),
                          if (isProcessing) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () => _completePayout(p['id']),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                  child: const Text('Mark Complete'),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton(
                                  onPressed: () => _failPayout(p['id']),
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                  child: const Text('Mark Failed'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),

          // Settlements Tab
          settlementsAsync.when(
            data: (settlements) {
              if (settlements.isEmpty) return const Center(child: Text('No settlements finalized.'));

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: settlements.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final s = settlements[index] as Map<String, dynamic>;
                  return Card(
                    child: ListTile(
                      title: Text('Settlement #${s['id'].toString().substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Gross: ₹${s['grossAmount']} • Net: ₹${s['netAmount']}'),
                      trailing: Text(s['status'] ?? 'FINALIZED', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }
}
