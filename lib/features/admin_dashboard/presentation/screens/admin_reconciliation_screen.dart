import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_finance_provider.dart';

class AdminReconciliationScreen extends ConsumerWidget {
  const AdminReconciliationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(adminReconciliationProvider(const {}));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Reconciliation Engine', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminReconciliationProvider(const {})),
          ),
        ],
      ),
      body: reportAsync.when(
        data: (data) {
          if (data == null) return const Center(child: Text('Failed to run reconciliation.'));

          final status = data['reconciliationStatus']?.toString() ?? 'UNKNOWN';
          final isHealthy = status == 'HEALTHY';
          final discrepancies = data['discrepancies'] as List? ?? [];
          final totals = data['totals'] as Map<String, dynamic>? ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (isHealthy ? Colors.green : Colors.red).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: (isHealthy ? Colors.green : Colors.red).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(isHealthy ? Icons.verified : Icons.warning_amber, color: isHealthy ? Colors.green : Colors.red, size: 28),
                          const SizedBox(width: 10),
                          Text(
                            'RECONCILIATION STATUS: $status',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isHealthy ? Colors.green.shade900 : Colors.red.shade900),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Total Records Audited: ${data['totalChecked']} • Discrepancies: ${data['discrepancyCount']}'),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Text('Audited Ledger Totals', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildRow('Gross Payments Captured', '₹${(totals['grossPayments'] ?? 0).toStringAsFixed(2)}'),
                        const Divider(),
                        _buildRow('Total Refunds Issued', '₹${(totals['totalRefunds'] ?? 0).toStringAsFixed(2)}'),
                        const Divider(),
                        _buildRow('Platform Revenue (Commission)', '₹${(totals['totalCommission'] ?? 0).toStringAsFixed(2)}'),
                        const Divider(),
                        _buildRow('Net Partner Payable', '₹${(totals['netPartnerPayable'] ?? 0).toStringAsFixed(2)}'),
                        const Divider(),
                        _buildRow('Total Completed Payouts', '₹${(totals['totalCompletedPayouts'] ?? 0).toStringAsFixed(2)}'),
                        const Divider(),
                        _buildRow('Outstanding Balance', '₹${(totals['outstandingBalance'] ?? 0).toStringAsFixed(2)}', isBold: true),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
                Text('Discrepancy Investigation Queue (${discrepancies.length})', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                if (discrepancies.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: Text('🎉 Zero discrepancies found! Every transaction and ledger entry reconciles perfectly.')),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: discrepancies.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = discrepancies[index] as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: Colors.red.shade100, child: const Icon(Icons.error_outline, color: Colors.red, size: 20)),
                          title: Text(item['code'] ?? 'DISCREPANCY', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          subtitle: Text(item['description'] ?? ''),
                          trailing: Chip(label: Text(item['severity'] ?? 'HIGH', style: const TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.red),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error running reconciliation: $e')),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w600, fontSize: isBold ? 15 : 13)),
        ],
      ),
    );
  }
}
