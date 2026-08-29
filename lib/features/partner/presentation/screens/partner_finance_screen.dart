import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/partner_providers.dart';

final partnerBalanceProvider = FutureProvider.autoDispose<PartnerFinanceBalance>((ref) async {
  final repo = ref.watch(partnerRepositoryProvider);
  final currentOrg = ref.watch(currentPartnerOrgProvider);
  if (currentOrg == null) return const PartnerFinanceBalance(availableBalance: 0, currency: 'INR');
  return repo.getBalance(currentOrg.id);
});

final partnerFinanceTransactionsProvider = FutureProvider.autoDispose<List<FinancialTransaction>>((ref) async {
  final repo = ref.watch(partnerRepositoryProvider);
  final currentOrg = ref.watch(currentPartnerOrgProvider);
  if (currentOrg == null) return [];
  return repo.getFinanceTransactions(currentOrg.id);
});

class PartnerFinanceScreen extends ConsumerWidget {
  const PartnerFinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(partnerBalanceProvider);
    final transactionsAsync = ref.watch(partnerFinanceTransactionsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Finance', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(partnerBalanceProvider);
          ref.invalidate(partnerFinanceTransactionsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available Balance',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      balanceAsync.when(
                        data: (balance) => Text(
                          '₹${balance.availableBalance.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        loading: () => const SizedBox(
                          height: 38,
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        error: (e, _) => const Text('Error', style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildQuickStat('Settled', '₹0.00'),
                          const SizedBox(width: 24),
                          _buildQuickStat('Pending', '₹0.00'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Recent Transactions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              transactionsAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No transactions yet'),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    separatorBuilder: (context, index) => const Divider(indent: 70),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      final isPositive = tx.type == 'PAYMENT';
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: (isPositive ? Colors.green : Colors.blue).withValues(alpha: 0.1),
                          child: Icon(
                            isPositive ? Icons.add : Icons.payment,
                            color: isPositive ? Colors.green : Colors.blue,
                            size: 20,
                          ),
                        ),
                        title: Text(tx.description ?? tx.type),
                        subtitle: Text(DateFormat('MMM dd, yyyy • hh:mm a').format(tx.createdAt)),
                        trailing: Text(
                          '${isPositive ? "+" : "-"} ₹${tx.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPositive ? Colors.green : Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading transactions: $e')),
              ),
              
              const SizedBox(height: 32),
              
              // Payout Button (Mock)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Payout request foundation ready for Phase 57.1')),
                       );
                    },
                    icon: const Icon(Icons.account_balance_wallet),
                    label: const Text('Request Payout'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}
