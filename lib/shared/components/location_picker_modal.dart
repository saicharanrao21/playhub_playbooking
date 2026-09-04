import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:playhub_playbooking/core/providers/location_provider.dart';
import 'package:playhub_playbooking/features/home/presentation/providers/discovery_provider.dart';

class LocationPickerModal extends ConsumerStatefulWidget {
  const LocationPickerModal({super.key});

  @override
  ConsumerState<LocationPickerModal> createState() => _LocationPickerModalState();
}

class _LocationPickerModalState extends ConsumerState<LocationPickerModal> {
  bool _isDetecting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final location = ref.watch(userLocationProvider);
    final citiesAsync = ref.watch(citiesProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 20.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Location & Radius',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Use GPS Location Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isDetecting
                  ? null
                  : () async {
                      setState(() => _isDetecting = true);
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);

                      final success = await ref.read(userLocationProvider.notifier).detectGpsLocation();
                      if (mounted) {
                        setState(() => _isDetecting = false);
                        if (success) {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('📍 Location updated using GPS'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          navigator.pop();
                        } else {
                          messenger.showSnackBar(
                            const SnackBar(
                              content: Text('⚠️ Unable to access GPS location. Please select city manually.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    },
              icon: _isDetecting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.my_location),
              label: const Text('Use Current GPS Location', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Text('Discovery Search Radius', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),

          // Radius Choice Chips
          Wrap(
            spacing: 8,
            children: [2.0, 5.0, 10.0, 25.0, 50.0].map((radiusKm) {
              final isSelected = location.radiusKm == radiusKm;
              return ChoiceChip(
                label: Text('${radiusKm.toInt()} km'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(userLocationProvider.notifier).updateRadius(radiusKm);
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          const Text('Or Pick Operating City', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),

          citiesAsync.when(
            data: (cities) => Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: cities.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final city = cities[index];
                  final isSelected = location.locationName.toLowerCase().contains(city.name.toLowerCase());

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.location_city, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant, size: 20),
                    ),
                    title: Text(city.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    subtitle: Text(city.state ?? 'India'),
                    trailing: isSelected ? Icon(Icons.check_circle, color: colorScheme.primary) : null,
                    onTap: () {
                      ref.read(selectedCityProvider.notifier).state = city;
                      // Fallback city center coordinates
                      double lat = 17.4401;
                      double lng = 78.3489;
                      if (city.name.toLowerCase().contains('bangalore')) {
                        lat = 12.9716;
                        lng = 77.5946;
                      }
                      ref.read(userLocationProvider.notifier).setManualLocation(lat, lng, city.name);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
            error: (err, _) => Text('Error loading cities: $err'),
          ),
        ],
      ),
    );
  }
}
