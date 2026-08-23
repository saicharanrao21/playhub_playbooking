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

  Future<void> _showCategoryDialog(BuildContext context, WidgetRef ref, [Category? category]) async {
    final nameController = TextEditingController(text: category?.name);
    final slugController = TextEditingController(text: category?.slug);
    final iconController = TextEditingController(text: category?.icon);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Add Category' : 'Edit Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: slugController, decoration: const InputDecoration(labelText: 'Slug')),
            TextField(controller: iconController, decoration: const InputDecoration(labelText: 'Icon Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final repo = ref.read(categoryRepositoryProvider);
              final data = {
                'name': nameController.text, 
                'slug': slugController.text,
                'icon': iconController.text,
              };
              final result = category == null 
                ? await repo.createCategory(data)
                : await repo.updateCategory(category.id, data);
              
              if (result != null) {
                ref.invalidate(adminCategoriesProvider);
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
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCategoryDialog(context, ref),
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
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showCategoryDialog(context, ref, category),
              ),
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
