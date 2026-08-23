import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/models/app_models.dart';

final adminCitiesProvider = FutureProvider<List<City>>((ref) async {
  final repo = ref.watch(cityRepositoryProvider);
  return repo.getCities();
});

class CityManagementScreen extends ConsumerWidget {
  const CityManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citiesAsync = ref.watch(adminCitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Cities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Show dialog to add city
            },
          ),
        ],
      ),
      body: citiesAsync.when(
        data: (cities) => ListView.builder(
          itemCount: cities.length,
          itemBuilder: (context, index) {
            final city = cities[index];
            return ListTile(
              title: Text(city.name),
              subtitle: Text(city.slug),
              trailing: const Icon(Icons.edit),
              onTap: () {
                // Show edit dialog
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
