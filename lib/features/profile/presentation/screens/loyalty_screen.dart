import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:playhub_playbooking/app/bootstrap/bootstrap.dart';

final loyaltyAccountProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get<Map<String, dynamic>>('/loyalty/account');
  return response.isSuccess ? response.data : null;
});

final loyaltyTransactionsProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get<Map<String, dynamic>>('/loyalty/transactions');
  return response.isSuccess ? response.data : null;
});

class LoyaltyScreen extends ConsumerWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountAsync = ref.watch(loyaltyAccountProvider);
    final txsAsync = ref.watch(loyaltyTransactionsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PlayHub Loyalty Rewards', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(loyaltyAccountProvider);
          ref.invalidate(loyaltyTransactionsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Loyalty Balance Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Loyalty Points Balance', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    accountAsync.when(
                      data: (acc) => Text(
                        '${acc?['pointsBalance'] ?? 0} Points',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      loading: () => const SizedBox(height: 38, child: CircularProgressIndicator(color: Colors.white)),
                      error: (e, _) => const Text('Error loading points', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(height: 8),
                    const Text('1 Point = ₹1 Discount on court bookings', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text('Points Ledger History', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              txsAsync.when(
                data: (data) {
                  final items = data?['items'] as List? ?? [];
                  if (items.isEmpty) return const Text('No points transactions recorded.');

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tx = items[index] as Map<String, dynamic>;
                      final points = tx['points'] ?? 0;
                      final isEarn = points > 0;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isEarn ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                          child: Icon(isEarn ? Icons.add : Icons.remove, color: isEarn ? Colors.green : Colors.red, size: 18),
                        ),
                        title: Text('Points ${tx['type']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(DateFormat('MMM dd, yyyy').format(DateTime.parse(tx['createdAt']))),
                        trailing: Text(
                          '${isEarn ? "+" : ""}$points pts',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isEarn ? Colors.green : Colors.red),
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
        ),
      ),
    );
  }
}
