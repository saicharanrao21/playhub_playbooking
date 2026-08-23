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

  Future<void> _showCityDialog(BuildContext context, WidgetRef ref, [City? city]) async {
    final nameController = TextEditingController(text: city?.name);
    final slugController = TextEditingController(text: city?.slug);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(city == null ? 'Add City' : 'Edit City'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: slugController, decoration: const InputDecoration(labelText: 'Slug')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final repo = ref.read(cityRepositoryProvider);
              final data = {'name': nameController.text, 'slug': slugController.text};
              final result = city == null 
                ? await repo.createCity(data)
                : await repo.updateCity(city.id, data);
              
              if (result != null) {
                ref.invalidate(adminCitiesProvider);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citiesAsync = ref.watch(adminCitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Cities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCityDialog(context, ref),
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
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showCityDialog(context, ref, city),
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
