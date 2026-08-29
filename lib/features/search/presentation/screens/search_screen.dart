import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:playhub_playbooking/features/search/presentation/providers/search_provider.dart';
import 'package:playhub_playbooking/features/home/presentation/providers/discovery_provider.dart';
import 'package:playhub_playbooking/shared/components/empty_view.dart';
import 'package:playhub_playbooking/shared/components/error_view.dart';
import 'package:playhub_playbooking/shared/components/loading_indicator.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;
  const SearchScreen({super.key, this.initialCategoryId});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

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
    super.dispose();
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
            hintText: 'Search sports venues, turf, activities...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchStateProvider.notifier).update((state) => state.copyWith(query: ''));
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            ref.read(searchStateProvider.notifier).update((state) => state.copyWith(query: value));
            setState(() {});
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: categoriesAsync.when(
            data: (categories) => SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                itemCount: categories.length + 1,
                separatorBuilder: (c, i) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final isAll = currentSearchState.categoryId == null;
                    return FilterChip(
                      label: const Text('All Categories'),
                      selected: isAll,
                      onSelected: (val) {
                        ref.read(searchStateProvider.notifier).update((state) => state.copyWith(categoryId: null));
                      },
                    );
                  }
                  final cat = categories[index - 1];
                  final isSelected = currentSearchState.categoryId == cat.id;
                  return FilterChip(
                    label: Text(cat.name),
                    selected: isSelected,
                    onSelected: (val) {
                      ref.read(searchStateProvider.notifier).update((state) => state.copyWith(categoryId: isSelected ? null : cat.id));
                    },
                  );
                },
              ),
            ),
            loading: () => const SizedBox(height: 44),
            error: (err, stack) => const SizedBox.shrink(),
          ),
        ),
      ),
      body: resultsAsync.when(
        data: (venues) {
          if (venues.isEmpty) {
            return EmptyView(
              icon: Icons.search_off_outlined,
              title: 'No venues found',
              message: 'Try searching with a different sport keyword or category filter.',
              actionLabel: 'Clear Filters',
              onAction: () {
                _searchController.clear();
                ref.read(searchStateProvider.notifier).update((state) => state.copyWith(query: '', categoryId: null));
              },
            );
          }

          return ListView.builder(
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
                      if (venue.imageUrls.isNotEmpty)
                        Image.network(
                          venue.imageUrls.first,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 160,
                            color: colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.image, size: 40, color: Colors.grey),
                          ),
                        )
                      else
                        Container(
                          height: 160,
                          color: colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: Icon(Icons.stadium, size: 48, color: colorScheme.primary.withValues(alpha: 0.6)),
                          ),
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
                                    Text(
                                      ' ${venue.rating.toStringAsFixed(1)} (${venue.reviewCount})',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 15, color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    venue.address,
                                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Starts from ₹500 / hr',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
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
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          itemBuilder: (c, i) => const SkeletonCard(height: 220),
        ),
        error: (err, stack) => AppErrorView(
          message: 'Error searching venues: $err',
          onRetry: () => ref.invalidate(searchResultsProvider),
        ),
      ),
    );
  }
}
