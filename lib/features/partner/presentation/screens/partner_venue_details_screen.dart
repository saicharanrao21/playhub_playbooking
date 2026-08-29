import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/partner_providers.dart';

class PartnerVenueDetailsScreen extends ConsumerWidget {
  final String venueId;

  const PartnerVenueDetailsScreen({super.key, required this.venueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venueAsync = ref.watch(partnerVenueDetailsProvider(venueId));
    final facilitiesAsync = ref.watch(partnerFacilitiesProvider(venueId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Venue & Courts', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(partnerVenueDetailsProvider(venueId));
              ref.invalidate(partnerFacilitiesProvider(venueId));
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/partner/venues/$venueId/facilities/create'),
        icon: const Icon(Icons.add),
        label: const Text('Add Court / Pitch'),
      ),
      body: venueAsync.when(
        data: (venue) {
          if (venue == null) return const Center(child: Text('Venue not found.'));

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(partnerVenueDetailsProvider(venueId));
              ref.invalidate(partnerFacilitiesProvider(venueId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Venue Header Card
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: colorScheme.primaryContainer,
                                radius: 24,
                                child: Icon(Icons.stadium, color: colorScheme.primary, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(venue.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    Text('${venue.address}, ${venue.city}', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(venue.status, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                              ),
                            ],
                          ),
                          if (venue.description != null && venue.description!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(venue.description!, style: const TextStyle(fontSize: 13)),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Courts, Pitches & Facilities', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      TextButton.icon(
                        onPressed: () => context.push('/partner/venues/$venueId/facilities/create'),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Court'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  facilitiesAsync.when(
                    data: (facilities) {
                      if (facilities.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.sports_tennis, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text('No Courts or Facilities Added', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(height: 4),
                              Text('Add courts, pitches, or tables for customers to book.', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => context.push('/partner/venues/$venueId/facilities/create'),
                                icon: const Icon(Icons.add),
                                label: const Text('Add First Court'),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: facilities.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, idx) {
                          final facility = facilities[idx];
                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: colorScheme.secondaryContainer,
                                    child: Icon(Icons.sports_soccer, color: colorScheme.secondary, size: 20),
                                  ),
                                  title: Text(facility.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Text('Capacity: ${facility.capacity} Players • ${facility.categoryName ?? "Sports"}', style: const TextStyle(fontSize: 12)),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: facility.status == PartnerFacilityStatus.active ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      facility.status.label,
                                      style: TextStyle(
                                        color: facility.status == PartnerFacilityStatus.active ? Colors.green : Colors.orange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                                const Divider(height: 1),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  child: Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => context.push(
                                          '/partner/venues/$venueId/facilities/${facility.id}/pricing',
                                          extra: {'facilityName': facility.name},
                                        ),
                                        icon: const Icon(Icons.payments_outlined, size: 16),
                                        label: const Text('Manage Pricing', style: TextStyle(fontSize: 12)),
                                      ),
                                      const Spacer(),
                                      TextButton.icon(
                                        onPressed: () {},
                                        icon: const Icon(Icons.event_busy_outlined, size: 16),
                                        label: const Text('Block Slot', style: TextStyle(fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Text('Error loading facilities: $err'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
