import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:playhub_playbooking/core/providers/location_provider.dart';
import 'package:playhub_playbooking/features/search/presentation/providers/search_provider.dart';
import 'package:playhub_playbooking/core/models/app_models.dart';

class MapViewScreen extends ConsumerStatefulWidget {
  const MapViewScreen({super.key});

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen> {
  final MapController _mapController = MapController();
  Venue? _selectedVenue;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(userLocationProvider);
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final searchState = ref.watch(searchStateProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final userCenter = LatLng(location.latitude, location.longitude);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Map View Discovery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(
              'Near ${location.locationName} (${searchState.radiusKm.toInt()} km radius)',
              style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Center on my location',
            onPressed: () {
              _mapController.move(userCenter, 13.5);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          searchResultsAsync.when(
            data: (venues) {
              final markers = <Marker>[];

              // 1. User Location Marker (Blue Pulsing Indicator)
              markers.add(
                Marker(
                  point: userCenter,
                  width: 44,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ),
                ),
              );

              // 2. Venue Markers
              for (final venue in venues) {
                if (venue.latitude != null && venue.longitude != null) {
                  final isSelected = _selectedVenue?.id == venue.id;

                  markers.add(
                    Marker(
                      point: LatLng(venue.latitude!, venue.longitude!),
                      width: 50,
                      height: 50,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _selectedVenue = venue);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected ? colorScheme.primary : colorScheme.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : colorScheme.primary,
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.sports_soccer,
                            size: 24,
                            color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  );
                }
              }

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: userCenter,
                  initialZoom: 12.5,
                  minZoom: 5.0,
                  maxZoom: 18.0,
                  onTap: (tapPosition, point) => setState(() => _selectedVenue = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.playhub.app',
                  ),
                  MarkerLayer(markers: markers),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error loading map venues: $err')),
          ),

          // Selected Venue Preview Card
          if (_selectedVenue != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 20,
              child: Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _selectedVenue!.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (_selectedVenue!.distanceFormatted != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _selectedVenue!.distanceFormatted!,
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_selectedVenue!.address}, ${_selectedVenue!.city}',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text('${_selectedVenue!.rating.toStringAsFixed(1)} (${_selectedVenue!.reviewCount})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: () {
                              context.push('/venue/${_selectedVenue!.id}');
                            },
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: const Text('View Courts & Book'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
