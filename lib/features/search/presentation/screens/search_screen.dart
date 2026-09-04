import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:playhub_playbooking/features/search/presentation/providers/search_provider.dart';
import 'package:playhub_playbooking/features/home/presentation/providers/discovery_provider.dart';
import 'package:playhub_playbooking/shared/components/empty_view.dart';
import 'package:playhub_playbooking/shared/components/error_view.dart';
import 'package:playhub_playbooking/shared/components/loading_indicator.dart';
import 'package:playhub_playbooking/shared/components/discovery_filter_modal.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  const SearchScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final selectedCity = ref.read(selectedCityProvider);
      ref.read(searchStateProvider.notifier).update((state) => state.copyWith(
            cityId: selectedCity?.id,
            categoryId: widget.initialCategoryId,
          ));
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(searchStateProvider.notifier).update(
              (state) => state.copyWith(query: value.trim()),
            );
      }
    });
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => const DiscoveryFilterModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final resultsAsync = ref.watch(searchResultsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    final currentSearchState = ref.watch(searchStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search sports venues, turf, badminton...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchStateProvider.notifier).update((state) => state.copyWith(clearQuery: true));
                      setState(() {});
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            _onSearchChanged(value);
            setState(() {});
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Filter Discovery',
            onPressed: _showFilterModal,
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Switch to Map View',
            onPressed: () => context.push('/map'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              children: [
                // Filter Modal Trigger Chip
                ActionChip(
                  avatar: const Icon(Icons.tune, size: 16),
                  label: const Text('Filters'),
                  onPressed: _showFilterModal,
                ),
                const SizedBox(width: 8),

                // Radius Chip
                ChoiceChip(
                  avatar: const Icon(Icons.navigation, size: 14),
                  label: Text('Within ${currentSearchState.radiusKm.toInt()} km'),
                  selected: true,
                  onSelected: (_) => _showFilterModal(),
                ),
                const SizedBox(width: 8),

                // Sort Chip
                ChoiceChip(
                  avatar: const Icon(Icons.sort, size: 14),
                  label: Text(currentSearchState.sortBy == 'distance'
                      ? 'Nearest'
                      : (currentSearchState.sortBy == 'price' ? 'Lowest Price' : 'Top Rated')),
                  selected: true,
                  onSelected: (_) => _showFilterModal(),
                ),
                const SizedBox(width: 8),

                // Category Filter Chips
                categoriesAsync.maybeWhen(
                  data: (categories) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: categories.map((cat) {
                      final isSelected = currentSearchState.categoryId == cat.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(cat.name),
                          selected: isSelected,
                          onSelected: (val) {
                            ref.read(searchStateProvider.notifier).update((state) => state.copyWith(
                                  categoryId: isSelected ? null : cat.id,
                                  clearCategory: isSelected,
                                ));
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
      body: resultsAsync.when(
        data: (venues) {
          if (venues.isEmpty) {
            return EmptyView(
              icon: Icons.search_off_outlined,
              title: 'No venues found nearby',
              message: 'Try increasing your search radius or clearing query filters.',
              actionLabel: 'Clear Search Filters',
              onAction: () {
                _searchController.clear();
                ref.read(searchStateProvider.notifier).update(
                      (state) => state.copyWith(
                        clearQuery: true,
                        clearCategory: true,
                        radiusKm: 25.0,
                      ),
                    );
              },
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(searchResultsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: venues.length,
              itemBuilder: (context, index) {
                final venue = venues[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.push('/venue/${venue.id}'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Container(
                              height: 150,
                              width: double.infinity,
                              color: colorScheme.surfaceContainerHighest,
                              child: venue.imageUrls.isNotEmpty
                                  ? Image.network(venue.imageUrls.first, fit: BoxFit.cover)
                                  : Icon(Icons.stadium, size: 56, color: colorScheme.primary.withValues(alpha: 0.5)),
                            ),
                            if (venue.distanceFormatted != null)
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.black87,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.navigation, color: Colors.white, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        venue.distanceFormatted!,
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      venue.name,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, size: 16, color: Colors.amber),
                                      const SizedBox(width: 2),
                                      Text(
                                        venue.rating.toStringAsFixed(1),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 15, color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${venue.address}, ${venue.city}',
                                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Courts Available',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => context.push('/venue/${venue.id}'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    child: const Text('View & Book'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          itemBuilder: (context, index) => const SkeletonCard(height: 220),
        ),
        error: (err, stack) => AppErrorView(
          message: 'Error searching venues: $err',
          onRetry: () => ref.invalidate(searchResultsProvider),
        ),
      ),
    );
  }
}
