import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/partner_providers.dart';

class PartnerPricingRulesScreen extends ConsumerWidget {
  final String venueId;
  final String facilityId;
  final String facilityName;

  const PartnerPricingRulesScreen({
    super.key,
    required this.venueId,
    required this.facilityId,
    required this.facilityName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(partnerPricingRulesProvider(facilityId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pricing Rules', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(facilityName, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(partnerPricingRulesProvider(facilityId).future),
        child: rulesAsync.when(
          data: (rules) {
            if (rules.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payments_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('No Pricing Rules', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Add rules to define how much customers pay for slots.'),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: rules.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final rule = rules[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    title: Text(rule.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (rule.daysOfWeek.isNotEmpty)
                          Text('Days: ${rule.daysOfWeek.join(", ")}', style: const TextStyle(fontSize: 12)),
                        if (rule.startTime != null && rule.endTime != null)
                          Text('Time: ${rule.startTime} - ${rule.endTime}', style: const TextStyle(fontSize: 12)),
                        Text('Priority: ${rule.priority}', style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${rule.basePrice.toStringAsFixed(0)}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.primary),
                        ),
                        const Text('/ hr', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(
          '/partner/venues/$venueId/facilities/$facilityId/pricing/create',
          extra: {'facilityName': facilityName},
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Rule'),
      ),
    );
  }
}
