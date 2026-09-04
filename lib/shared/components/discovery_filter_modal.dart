import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:playhub_playbooking/features/search/presentation/providers/search_provider.dart';
import 'package:playhub_playbooking/features/home/presentation/providers/discovery_provider.dart';

class DiscoveryFilterModal extends ConsumerWidget {
  const DiscoveryFilterModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final searchState = ref.watch(searchStateProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Discovery Filters',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  ref.read(searchStateProvider.notifier).update((state) => state.copyWith(
                    clearQuery: true,
                    clearCategory: true,
                    clearActivity: true,
                    radiusKm: 10.0,
                    sortBy: 'distance',
                  ));
                  Navigator.pop(context);
                },
                child: const Text('Reset All'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Radius Section
          const Text('Search Radius', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [2.0, 5.0, 10.0, 25.0, 50.0].map((radiusKm) {
              final isSelected = searchState.radiusKm == radiusKm;
              return ChoiceChip(
                label: Text('${radiusKm.toInt()} km'),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(searchStateProvider.notifier).update(
                          (state) => state.copyWith(radiusKm: radiusKm),
                        );
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Sorting Section
          const Text('Sort Venues By', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              {'id': 'distance', 'label': 'Nearest First'},
              {'id': 'rating', 'label': 'Highest Rated'},
              {'id': 'price', 'label': 'Lowest Price'},
            ].map((sortItem) {
              final isSelected = searchState.sortBy == sortItem['id'];
              return ChoiceChip(
                label: Text(sortItem['label']!),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(searchStateProvider.notifier).update(
                          (state) => state.copyWith(sortBy: sortItem['id']),
                        );
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Sports Categories Section
          const Text('Sport Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          categoriesAsync.when(
            data: (categories) => Wrap(
              spacing: 8,
              children: categories.map((cat) {
                final isSelected = searchState.categoryId == cat.id;
                return ChoiceChip(
                  label: Text(cat.name),
                  selected: isSelected,
                  onSelected: (selected) {
                    ref.read(searchStateProvider.notifier).update(
                          (state) => state.copyWith(
                            categoryId: selected ? cat.id : null,
                            clearCategory: !selected,
                          ),
                        );
                  },
                );
              }).toList(),
            ),
            loading: () => const SizedBox(height: 32, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('Error loading categories: $e'),
          ),

          const SizedBox(height: 28),

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
