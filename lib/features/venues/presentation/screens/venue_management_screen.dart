import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../domain/models/venue_models.dart';
import 'package:go_router/go_router.dart';

final operatorVenuesProvider = FutureProvider<List<Venue>>((ref) async {
  final repo = ref.watch(venueOperatorRepositoryProvider);
  return repo.getVenues();
});

class VenueManagementScreen extends ConsumerWidget {
  const VenueManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(operatorVenuesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Venues'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to create venue screen
            },
          ),
        ],
      ),
      body: venuesAsync.when(
        data: (venues) => RefreshIndicator(
          onRefresh: () => ref.refresh(operatorVenuesProvider.future),
          child: venues.isEmpty
              ? const Center(child: Text('No venues found for your organization.'))
              : ListView.builder(
                  itemCount: venues.length,
                  itemBuilder: (context, index) {
                    final venue = venues[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(venue.name),
                        subtitle: Text('${venue.city} - ${venue.status.name.toUpperCase()}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo_library),
                        onPressed: () => context.push('/business-dashboard/venues/${venue.id}/media'),
                      ),
                      const Icon(Icons.edit),
                    ],
                  ),
                  onTap: () {
                    // Navigate to edit venue screen
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
