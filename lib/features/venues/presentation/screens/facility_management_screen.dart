import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../domain/models/venue_models.dart';
import 'package:go_router/go_router.dart';

final operatorFacilitiesProvider = FutureProvider.family<List<Facility>, String>((ref, venueId) async {
  final repo = ref.watch(venueOperatorRepositoryProvider);
  return repo.getFacilities(venueId);
});

class FacilityManagementScreen extends ConsumerWidget {
  final String venueId;
  const FacilityManagementScreen({super.key, required this.venueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facilitiesAsync = ref.watch(operatorFacilitiesProvider(venueId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Facilities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/business-dashboard/venues/$venueId/facilities/create'),
          ),
        ],
      ),
      body: facilitiesAsync.when(
        data: (facilities) => RefreshIndicator(
          onRefresh: () => ref.refresh(operatorFacilitiesProvider(venueId).future),
          child: facilities.isEmpty
              ? const Center(child: Text('No facilities found for this venue.'))
              : ListView.builder(
                  itemCount: facilities.length,
                  itemBuilder: (context, index) {
                    final facility = facilities[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(facility.name),
                        subtitle: Text(facility.status.name.toUpperCase()),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.photo_library),
                              onPressed: () => context.push('/business-dashboard/venues/$venueId/facilities/${facility.id}/media'),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => context.push('/business-dashboard/venues/$venueId/facilities/${facility.id}/edit'),
                            ),
                          ],
                        ),
                        onTap: () {
                          // Navigate to edit facility
                        },
                      ),
                    );
                  },
                ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
