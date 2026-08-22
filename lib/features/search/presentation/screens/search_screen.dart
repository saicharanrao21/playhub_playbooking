import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/search_provider.dart';
import '../../../home/presentation/providers/discovery_provider.dart';
import 'package:go_router/go_router.dart';

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
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search venues...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
             ref.read(searchStateProvider.notifier).update((state) => state.copyWith(query: value));
          },
        ),
      ),
      body: resultsAsync.when(
        data: (venues) => venues.isEmpty
            ? const Center(child: Text('No venues found matching your search.'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: venues.length,
                itemBuilder: (context, index) {
                  final venue = venues[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: venue.imageUrls.isNotEmpty 
                        ? Image.network(venue.imageUrls.first, width: 60, height: 60, fit: BoxFit.cover)
                        : const Icon(Icons.business, size: 40),
                      title: Text(venue.name),
                      subtitle: Text(venue.address),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/venue/${venue.id}'),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
