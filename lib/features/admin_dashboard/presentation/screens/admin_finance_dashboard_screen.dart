import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_finance_provider.dart';

class AdminFinanceDashboardScreen extends ConsumerWidget {
  const AdminFinanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(adminFinanceOverviewProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Governance & Audit', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminFinanceOverviewProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminFinanceOverviewProvider),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Platform-Wide Financial Telemetry',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              overviewAsync.when(
                data: (overview) {
                  final totals = overview?['totals'] as Map<String, dynamic>? ?? {};
                  final isHealthy = overview?['reconciliationStatus'] == 'HEALTHY';

                  return Column(
                    children: [
                      // Reconciliation Status Banner
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: (isHealthy ? Colors.green : Colors.red).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: (isHealthy ? Colors.green : Colors.red).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isHealthy ? Icons.check_circle : Icons.warning,
                              color: isHealthy ? Colors.green : Colors.red,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isHealthy ? 'Financial Ledger: Balanced & Healthy' : 'Discrepancies Detected in Ledger!',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isHealthy ? Colors.green.shade800 : Colors.red.shade800,
                                    ),
                                  ),
                                  Text(
                                    isHealthy
                                        ? 'All captured payments, double-entry ledgers & payouts reconcile.'
                                        : 'Click "Reconciliation Engine" below to investigate discrepancies.',
                                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.4,
                        children: [
                          _buildStatTile(context, 'Gross Volume (GMV)', '₹${(totals['grossPayments'] ?? 0).toStringAsFixed(0)}', Icons.payments, Colors.blue),
                          _buildStatTile(context, 'Total Refunds', '₹${(totals['totalRefunds'] ?? 0).toStringAsFixed(0)}', Icons.undo, Colors.red),
                          _buildStatTile(context, 'Platform Revenue', '₹${(totals['totalCommission'] ?? 0).toStringAsFixed(0)}', Icons.point_of_sale, Colors.green),
                          _buildStatTile(context, 'Partner Payable', '₹${(totals['netPartnerPayable'] ?? 0).toStringAsFixed(0)}', Icons.account_balance_wallet, Colors.orange),
                        ],
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
                error: (e, _) => Text('Error loading finance metrics: $e'),
              ),

              const SizedBox(height: 28),
              Text(
                'Financial Governance & Operations',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal.shade100,
                        child: const Icon(Icons.fact_check, color: Colors.teal),
                      ),
                      title: const Text('Reconciliation Engine', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Run double-entry ledger audits & verify provider balance'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/admin-dashboard/finance/reconciliation'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple.shade100,
                        child: const Icon(Icons.percent, color: Colors.purple),
                      ),
                      title: const Text('Commission Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Manage global & organization-specific platform fee rules'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/admin-dashboard/finance/commissions'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo.shade100,
                        child: const Icon(Icons.account_balance, color: Colors.indigo),
                      ),
                      title: const Text('Settlements & Payouts', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Review partner payouts, settlements & bank transfers'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/admin-dashboard/finance/settlements'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade100,
                        child: const Icon(Icons.tune, color: Colors.orange),
                      ),
                      title: const Text('Governed Financial Adjustments', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Issue credits, penalties, or goodwill partner adjustments'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/admin-dashboard/finance/adjustments'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatTile(BuildContext context, String title, String value, IconData icon, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 10), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
