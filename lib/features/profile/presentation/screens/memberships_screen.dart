import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:playhub_playbooking/app/bootstrap/bootstrap.dart';

final membershipPlansProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get<List<dynamic>>('/memberships/plans', authenticated: false);
  return response.isSuccess ? (response.data ?? []) : [];
});

final customerActiveMembershipProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get<Map<String, dynamic>>('/memberships/my-membership');
  return response.isSuccess ? response.data : null;
});

class MembershipsScreen extends ConsumerStatefulWidget {
  const MembershipsScreen({super.key});

  @override
  ConsumerState<MembershipsScreen> createState() => _MembershipsScreenState();
}

class _MembershipsScreenState extends ConsumerState<MembershipsScreen> {
  bool _isPurchasing = false;

  Future<void> _purchasePlan(Map<String, dynamic> plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Join ${plan['name']}'),
        content: Text('Purchase ${plan['name']} for ₹${plan['price']} / ${plan['duration']} ${plan['durationUnit']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Confirm Purchase')),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isPurchasing = true);
      try {
        final apiClient = ref.read(apiClientProvider);
        final response = await apiClient.post(
          '/memberships/purchase',
          data: {'planId': plan['id']},
        );

        if (mounted) {
          if (response.isSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🎉 Membership activated successfully!'), backgroundColor: Colors.green),
            );
            ref.invalidate(customerActiveMembershipProvider);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Membership purchase failed.'), backgroundColor: Colors.red),
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
        if (mounted) setState(() => _isPurchasing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeMembershipAsync = ref.watch(customerActiveMembershipProvider);
    final plansAsync = ref.watch(membershipPlansProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PlayHub Memberships', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(customerActiveMembershipProvider);
          ref.invalidate(membershipPlansProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Active Membership Card
              activeMembershipAsync.when(
                data: (membership) {
                  if (membership == null) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('No Active Membership', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 4),
                          Text('Join a membership plan below for exclusive discounts & priority court access.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  final plan = membership['plan'] as Map<String, dynamic>? ?? {};
                  final expiry = DateTime.parse(membership['expiryDate']);

                  return Container(
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(plan['name'] ?? 'PlayHub VIP', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                            Chip(label: const Text('ACTIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)), backgroundColor: Colors.green),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Expires: ${DateFormat('MMM dd, yyyy').format(expiry)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
                error: (e, _) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 24),
              Text('Available Membership Plans', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              plansAsync.when(
                data: (plans) {
                  if (plans.isEmpty) return const Text('No membership plans available.');

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: plans.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = plans[index] as Map<String, dynamic>;
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(p['name'] ?? 'Plan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('₹${p['price']} / ${p['duration']} ${p['durationUnit']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.primary)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(p['description'] ?? 'Includes court booking discounts and priority booking access.', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isPurchasing ? null : () => _purchasePlan(p),
                                  child: const Text('Join Plan', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error loading plans: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
