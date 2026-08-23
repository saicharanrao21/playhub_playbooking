import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/models/app_models.dart';

final adminActivitiesProvider = FutureProvider<List<Activity>>((ref) async {
  final repo = ref.watch(activityRepositoryProvider);
  return repo.getActivities();
});

class ActivityManagementScreen extends ConsumerWidget {
  const ActivityManagementScreen({super.key});

  Future<void> _showActivityDialog(BuildContext context, WidgetRef ref, [Activity? activity]) async {
    final nameController = TextEditingController(text: activity?.name);
    final slugController = TextEditingController(text: activity?.slug);
    final iconController = TextEditingController(text: activity?.icon);
    String? selectedCategoryId = activity?.categoryId;

    final categories = await ref.read(categoryRepositoryProvider).getCategories();

    if (!context.mounted) return;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(activity == null ? 'Add Activity' : 'Edit Activity'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedCategoryId,
                decoration: const InputDecoration(labelText: 'Category'),
                items: categories.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                )).toList(),
                onChanged: (v) => setState(() => selectedCategoryId = v),
              ),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: slugController, decoration: const InputDecoration(labelText: 'Slug')),
              TextField(controller: iconController, decoration: const InputDecoration(labelText: 'Icon Name')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final repo = ref.read(activityRepositoryProvider);
                final data = {
                  'categoryId': selectedCategoryId,
                  'name': nameController.text, 
                  'slug': slugController.text,
                  'icon': iconController.text,
                };
                final result = activity == null 
                  ? await repo.createActivity(data)
                  : await repo.updateActivity(activity.id, data);
                
                if (result != null) {
                  ref.invalidate(adminActivitiesProvider);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activitiesAsync = ref.watch(adminActivitiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Activities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showActivityDialog(context, ref),
          ),
        ],
      ),
      body: activitiesAsync.when(
        data: (activities) => ListView.builder(
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return ListTile(
              leading: Icon(_getIcon(activity.icon)),
              title: Text(activity.name),
              subtitle: Text(activity.slug),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showActivityDialog(context, ref, activity),
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
      default: return Icons.sports;
    }
  }
}
