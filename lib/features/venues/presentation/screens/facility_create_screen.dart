import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/bootstrap/bootstrap.dart';
import '../../../../core/security/auth_provider.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/models/app_models.dart' as core;
import 'package:go_router/go_router.dart';

class FacilityCreateScreen extends ConsumerStatefulWidget {
  final String venueId;
  const FacilityCreateScreen({super.key, required this.venueId});

  @override
  ConsumerState<FacilityCreateScreen> createState() => _FacilityCreateScreenState();
}

class _FacilityCreateScreenState extends ConsumerState<FacilityCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedActivityId;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final orgId = ref.read(activeOrganizationProvider);
      
      final response = await apiClient.post(
        '/organizations/$orgId/venues/${widget.venueId}/facilities',
        data: {
          'name': _nameController.text,
          'description': _descController.text,
          'categoryId': _selectedCategoryId,
          'activityId': _selectedActivityId,
          'capacity': 10, // Default
        },
      );

      if (response.isSuccess) {
        if (mounted) context.pop();
      } else {
        throw Exception(response.statusMessage ?? 'Failed to create facility');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryRepositoryProvider.select((repo) => repo.getCategories()));

    return Scaffold(
      appBar: AppBar(title: const Text('Create Facility')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Facility Name'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<core.Category>>(
              future: categoriesAsync,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                return DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: snapshot.data!.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                  validator: (v) => v == null ? 'Required' : null,
                );
              }
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving ? const CircularProgressIndicator() : const Text('Create Facility'),
            ),
          ],
        ),
      ),
    );
  }
}
