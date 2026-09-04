import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/partner_providers.dart';

final partnerFinanceSummaryProvider = FutureProvider.autoDispose<PartnerFinanceSummary>((ref) async {
  final repo = ref.watch(partnerRepositoryProvider);
  final currentOrg = ref.watch(currentPartnerOrgProvider);
  if (currentOrg == null) return const PartnerFinanceSummary(availableBalance: 0, currency: 'INR');
  return repo.getFinancialSummary(currentOrg.id);
});

final partnerFinanceTransactionsProvider = FutureProvider.autoDispose<List<FinancialTransaction>>((ref) async {
  final repo = ref.watch(partnerRepositoryProvider);
  final currentOrg = ref.watch(currentPartnerOrgProvider);
  if (currentOrg == null) return [];
  return repo.getFinanceTransactions(currentOrg.id);
});

final partnerPayoutsProvider = FutureProvider.autoDispose<List<PartnerPayoutItem>>((ref) async {
  final repo = ref.watch(partnerRepositoryProvider);
  final currentOrg = ref.watch(currentPartnerOrgProvider);
  if (currentOrg == null) return [];
  return repo.getPayouts(currentOrg.id);
});

class PartnerFinanceScreen extends ConsumerStatefulWidget {
  const PartnerFinanceScreen({super.key});

  @override
  ConsumerState<PartnerFinanceScreen> createState() => _PartnerFinanceScreenState();
}

class _PartnerFinanceScreenState extends ConsumerState<PartnerFinanceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRequestingPayout = false;

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

  Future<void> _handleRequestPayout(double availableBalance) async {
    final currentOrg = ref.read(currentPartnerOrgProvider);
    if (currentOrg == null) return;

    if (currentOrg.kycStatus != PartnerKYCStatus.approved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Payouts require an Approved KYC status.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (availableBalance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available balance for payout request.'),
        ),
      );
      return;
    }

    final amountController = TextEditingController(text: availableBalance.toStringAsFixed(0));
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Payout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Available Balance: ₹${availableBalance.toStringAsFixed(2)}'),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Payout Amount (₹)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Destination: ${currentOrg.bankName ?? "Bank"} • ${_maskAccountNumber(currentOrg.accountNumber)}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm Request'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final requestedAmount = double.tryParse(amountController.text) ?? 0.0;
      if (requestedAmount <= 0 || requestedAmount > availableBalance) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid payout amount'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      setState(() => _isRequestingPayout = true);
      try {
        final repo = ref.read(partnerRepositoryProvider);
        final success = await repo.requestPayout(currentOrg.id, requestedAmount);

        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎉 Payout request submitted successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            ref.invalidate(partnerFinanceSummaryProvider);
            ref.invalidate(partnerPayoutsProvider);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payout request failed.'), backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isRequestingPayout = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(partnerFinanceSummaryProvider);
    final currentOrg = ref.watch(currentPartnerOrgProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Finance & Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(partnerFinanceSummaryProvider);
          ref.invalidate(partnerFinanceTransactionsProvider);
          ref.invalidate(partnerPayoutsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance & Summary Banner Card
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colorScheme.primary, colorScheme.secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Net Available Payable',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      summaryAsync.when(
                        data: (summary) => Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '₹${summary.availableBalance.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              summary.currency,
                              style: const TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                        loading: () => const SizedBox(
                          height: 38,
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                        error: (e, _) => const Text('Error loading balance', style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 12),
                      summaryAsync.maybeWhen(
                        data: (summary) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatColumn('Gross Earnings', '₹${summary.grossEarnings.toStringAsFixed(0)}'),
                            _buildStatColumn('Commission (10%)', '₹${summary.totalCommission.toStringAsFixed(0)}'),
                            _buildStatColumn('Paid Out', '₹${summary.totalPaidOut.toStringAsFixed(0)}'),
                          ],
                        ),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),

              // Bank Payout Account Info Card
              if (currentOrg != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          Icon(Icons.account_balance, color: colorScheme.primary, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentOrg.bankName ?? 'Settlement Bank Account',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  'A/C: ${_maskAccountNumber(currentOrg.accountNumber)} • IFSC: ${currentOrg.ifscCode ?? "N/A"}',
                                  style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: currentOrg.kycStatus == PartnerKYCStatus.approved
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              currentOrg.kycStatus == PartnerKYCStatus.approved ? 'KYC VERIFIED' : 'KYC PENDING',
                              style: TextStyle(
                                color: currentOrg.kycStatus == PartnerKYCStatus.approved ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Request Payout Action Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isRequestingPayout
                        ? null
                        : () {
                            final balance = summaryAsync.asData?.value.availableBalance ?? 0.0;
                            _handleRequestPayout(balance);
                          },
                    icon: _isRequestingPayout
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.account_balance_wallet_outlined),
                    label: const Text('Request Payout Settlement', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Tab Bar for Ledger vs Payouts
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Ledger Transactions'),
                  Tab(text: 'Payout History'),
                ],
              ),

              SizedBox(
                height: 400,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTransactionsTab(),
                    _buildPayoutsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsTab() {
    final transactionsAsync = ref.watch(partnerFinanceTransactionsProvider);

    return transactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No financial ledger transactions recorded yet.'),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: transactions.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final tx = transactions[index];
            final isPayment = tx.type == 'PAYMENT';
            final isRefund = tx.type == 'REFUND';

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              leading: CircleAvatar(
                backgroundColor: isPayment
                    ? Colors.green.withValues(alpha: 0.15)
                    : (isRefund ? Colors.red.withValues(alpha: 0.15) : Colors.blue.withValues(alpha: 0.15)),
                child: Icon(
                  isPayment ? Icons.add : (isRefund ? Icons.remove : Icons.swap_horiz),
                  color: isPayment ? Colors.green : (isRefund ? Colors.red : Colors.blue),
                  size: 18,
                ),
              ),
              title: Text(
                tx.description ?? tx.type,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              subtitle: Text(
                DateFormat('MMM dd, yyyy • h:mm a').format(tx.createdAt),
                style: const TextStyle(fontSize: 11),
              ),
              trailing: Text(
                '${isPayment ? "+" : "-"} ₹${tx.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isPayment ? Colors.green : (isRefund ? Colors.red : Colors.black87),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading ledger: $e')),
    );
  }

  Widget _buildPayoutsTab() {
    final payoutsAsync = ref.watch(partnerPayoutsProvider);

    return payoutsAsync.when(
      data: (payouts) {
        if (payouts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No payout requests or settlements recorded.'),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: payouts.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final payout = payouts[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              leading: const CircleAvatar(
                child: Icon(Icons.outbox, size: 18),
              ),
              title: Text('Payout #${payout.id.substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text('Status: ${payout.status} • ${DateFormat('MMM dd, yyyy').format(payout.createdAt)}'),
              trailing: Text(
                '₹${payout.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading payouts: $e')),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  String _maskAccountNumber(String? num) {
    if (num == null || num.length < 4) return 'XXXXXX1234';
    return 'XXXXXX${num.substring(num.length - 4)}';
  }
}
