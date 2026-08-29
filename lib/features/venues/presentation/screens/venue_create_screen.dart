import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/bootstrap/bootstrap.dart';
import '../../../../core/security/auth_provider.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/models/app_models.dart';
import 'package:go_router/go_router.dart';

class VenueCreateScreen extends ConsumerStatefulWidget {
  const VenueCreateScreen({super.key});

  @override
  ConsumerState<VenueCreateScreen> createState() => _VenueCreateScreenState();
}

class _VenueCreateScreenState extends ConsumerState<VenueCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _slugController = TextEditingController();
  String? _selectedCityId;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _slugController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final orgId = ref.read(activeOrganizationProvider);
      
      // Need a business ID. In this MVP, let's assume we fetch the first business of the org.
      final businessesResponse = await apiClient.get<List>('/organizations/$orgId/businesses');
      if (businessesResponse.data == null || businessesResponse.data!.isEmpty) {
        throw Exception('No business associated with this organization.');
      }
      final businessId = businessesResponse.data!.first['id'];

      final response = await apiClient.post(
        '/organizations/$orgId/venues',
        queryParameters: {'businessId': businessId},
        data: {
          'name': _nameController.text,
          'slug': _slugController.text,
          'address': _addressController.text,
          'city': 'N/A', 
          'state': 'N/A',
          'country': 'India',
          'postalCode': '000000',
          'cityId': _selectedCityId,
        },
      );

      if (response.isSuccess) {
        if (mounted) context.pop();
      } else {
        throw Exception(response.statusMessage ?? 'Failed to create venue');
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
    final citiesAsync = ref.watch(cityRepositoryProvider.select((repo) => repo.getCities()));

    return Scaffold(
      appBar: AppBar(title: const Text('Create Venue')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Venue Name'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              onChanged: (v) {
                if (_slugController.text.isEmpty || _slugController.text == _nameController.text.toLowerCase().replaceAll(' ', '-')) {
                   _slugController.text = v.toLowerCase().replaceAll(' ', '-');
                }
              },
            ),
            TextFormField(
              controller: _slugController,
              decoration: const InputDecoration(labelText: 'Slug (URL handle)'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<City>>(
              future: citiesAsync,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                return DropdownButtonFormField<String>(
                  initialValue: _selectedCityId,
                  decoration: const InputDecoration(labelText: 'City'),
                  items: snapshot.data!.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedCityId = v),
                  validator: (v) => v == null ? 'Required' : null,
                );
              }
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving ? const CircularProgressIndicator() : const Text('Create Venue'),
            ),
          ],
        ),
      ),
    );
  }
}
