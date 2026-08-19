import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:playhub_playbooking/core/providers/repository_providers.dart';
import '../../domain/models/venue_models.dart' as domain;
import '../../data/venue_repository.dart';
import 'package:go_router/go_router.dart';

final venueDetailsProvider = FutureProvider.family<domain.Venue?, String>((
  ref,
  id,
) async {
  final repo = ref.watch(venueRepositoryProvider);
  if (repo is VenueRepository) {
    return repo.getFullVenue(id);
  }
  
  final venue = await repo.getVenueById(id);
  if (venue == null) return null;
  
  return domain.Venue(
    id: venue.id,
    businessId: venue.businessId,
    name: venue.name,
    slug: '',
    description: venue.description,
    address: venue.address,
    city: venue.city,
    state: '',
    country: '',
    postalCode: '',
    timezone: 'UTC',
    status: domain.VenueStatus.active,
    facilities: venue.facilities?.map((f) => domain.Facility(
      id: f.id,
      venueId: venue.id,
      categoryId: '',
      name: f.name,
      description: f.description,
      status: domain.FacilityStatus.active,
    )).toList(),
  );
});

class VenueDetailsScreen extends ConsumerWidget {
  final String venueId;
  const VenueDetailsScreen({super.key, required this.venueId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venueAsync = ref.watch(venueDetailsProvider(venueId));

    return Scaffold(
      body: venueAsync.when(
        data: (domain.Venue? venue) {
          if (venue == null) {
            return const Center(child: Text('Venue not found'));
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: const Placeholder(), 
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              venue.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(venue.description ?? ''),
                      const SizedBox(height: 24),
                      const Text(
                        'Facilities',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (venue.facilities != null && venue.facilities!.isNotEmpty)
                        Column(
                          children: venue.facilities!.map((f) => Card(
                            child: ListTile(
                              title: Text(f.name),
                              subtitle: Text(f.description ?? ''),
                              trailing: ElevatedButton(
                                onPressed: () => context.push(
                                  '/availability/${f.id}',
                                  extra: {'facilityName': f.name},
                                ),
                                child: const Text('Check Availability'),
                              ),
                            ),
                          )).toList(),
                        )
                      else
                        const Text('No facilities listed for this venue.'),
                      const SizedBox(height: 100), 
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
