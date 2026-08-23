import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/models/app_models.dart';

final adminCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getCategories();
});

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Show dialog to add category
            },
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) => ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return ListTile(
              leading: Icon(_getIcon(category.icon)),
              title: Text(category.name),
              subtitle: Text(category.slug),
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

  IconData _getIcon(String? iconName) {
    switch (iconName) {
      case 'sports_soccer': return Icons.sports_soccer;
      case 'sports_cricket': return Icons.sports_cricket;
      case 'sports_tennis': return Icons.sports_tennis;
      case 'pool': return Icons.pool;
      case 'fitness_center': return Icons.fitness_center;
      default: return Icons.category;
    }
  }
}
