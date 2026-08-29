import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:playhub_playbooking/core/providers/repository_providers.dart';
import 'package:playhub_playbooking/core/security/auth_provider.dart';
import 'package:playhub_playbooking/core/security/permissions.dart';
import 'package:playhub_playbooking/shared/components/error_view.dart';
import 'package:playhub_playbooking/shared/components/status_badge.dart';
import '../../domain/models/venue_models.dart' as domain;
import '../../data/venue_repository.dart';

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
    media: [],
    facilities: venue.facilities?.map((f) => domain.Facility(
      id: f.id,
      venueId: venue.id,
      categoryId: '',
      name: f.name,
      description: f.description,
      status: domain.FacilityStatus.active,
      media: [],
    )).toList(),
  );
});

class VenueDetailsScreen extends ConsumerStatefulWidget {
  final String venueId;
  const VenueDetailsScreen({super.key, required this.venueId});

  @override
  ConsumerState<VenueDetailsScreen> createState() => _VenueDetailsScreenState();
}

class _VenueDetailsScreenState extends ConsumerState<VenueDetailsScreen> {
  bool _isFavorite = false;

  final List<String> _amenities = [
    'Floodlights',
    'Ample Parking',
    'Changing Rooms',
    'Mineral Water',
    'First Aid',
    'Restrooms',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final venueAsync = ref.watch(venueDetailsProvider(widget.venueId));

    return Scaffold(
      body: venueAsync.when(
        data: (domain.Venue? venue) {
          if (venue == null) {
            return const Scaffold(
              body: Center(child: Text('Venue not found')),
            );
          }

          final facilities = venue.facilities ?? [];

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                actions: [
                  IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : Colors.white,
                    ),
                    onPressed: () {
                      setState(() => _isFavorite = !_isFavorite);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isFavorite ? 'Saved to Favorites' : 'Removed from Favorites'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined, color: Colors.white),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Venue link copied to clipboard!')),
                      );
                    },
                  ),
                  if (ref.can(AppPermissions.venueUpdate))
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.white),
                      onPressed: () => context.push('/business/venues/edit/${venue.id}'),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      venue.imageUrls.isNotEmpty
                          ? Image.network(
                              venue.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.image_not_supported, size: 80, color: Colors.grey),
                              ),
                            )
                          : Container(
                              color: colorScheme.primaryContainer,
                              child: Icon(Icons.stadium, size: 80, color: colorScheme.primary),
                            ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.5),
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Venue Title & Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              venue.name,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const StatusBadge(status: 'ACTIVE'),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Rating & Reviews
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.star, size: 16, color: Colors.amber),
                                SizedBox(width: 4),
                                Text('4.8', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(24 verified reviews)',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Location & Address
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on_outlined, color: colorScheme.primary, size: 20),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '${venue.address}, ${venue.city}',
                              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Description Section
                      Text(
                        'About This Venue',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (venue.description != null && venue.description!.isNotEmpty)
                            ? venue.description!
                            : 'Experience world-class sports facilities designed for recreational players and competitive athletes alike.',
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5, color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 24),

                      // Amenities Chips Section
                      Text(
                        'Amenities & Highlights',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _amenities.map((amenity) {
                          return Chip(
                            avatar: Icon(Icons.check_circle, size: 16, color: colorScheme.primary),
                            label: Text(amenity, style: const TextStyle(fontSize: 12)),
                            backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                            side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      // Available Facilities Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Facilities at this Venue (${facilities.length})',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (facilities.isNotEmpty)
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: facilities.length,
                          separatorBuilder: (c, i) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final f = facilities[index];
                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 70,
                                        height: 70,
                                        color: colorScheme.primaryContainer,
                                        child: (f.imageUrls.isNotEmpty)
                                            ? Image.network(f.imageUrls.first, fit: BoxFit.cover)
                                            : Icon(Icons.sports_soccer, size: 36, color: colorScheme.primary),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            f.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            f.description ?? 'Active turf ready for match booking',
                                            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => context.push(
                                        '/availability/${f.id}',
                                        extra: {'facilityName': f.name},
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                      child: const Text('Book', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      else
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No active facilities listed for this venue currently.'),
                          ),
                        ),

                      const SizedBox(height: 120), // Padding for sticky bottom sheet
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator.adaptive()),
        ),
        error: (err, stack) => Scaffold(
          appBar: AppBar(),
          body: AppErrorView(
            message: 'Failed to load venue details: $err',
            onRetry: () => ref.invalidate(venueDetailsProvider(widget.venueId)),
          ),
        ),
      ),
      bottomSheet: venueAsync.maybeWhen(
        data: (venue) {
          if (venue == null) return const SizedBox.shrink();
          final facilities = venue.facilities ?? [];
          final defaultFacility = facilities.isNotEmpty ? facilities.first : null;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Starting from',
                        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                      ),
                      Text(
                        '₹500 / hr',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: defaultFacility != null
                        ? () => context.push(
                              '/availability/${defaultFacility.id}',
                              extra: {'facilityName': defaultFacility.name},
                            )
                        : () => ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select a facility from the list above.')),
                            ),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('Check Availability', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        orElse: () => const SizedBox.shrink(),
      ),
    );
  }
}
