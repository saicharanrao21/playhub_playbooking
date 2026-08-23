import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/bootstrap/bootstrap.dart';
import '../../../../core/security/auth_provider.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../domain/models/venue_models.dart';
import 'package:go_router/go_router.dart';

class FacilityEditScreen extends ConsumerStatefulWidget {
  final String venueId;
  final String facilityId;
  const FacilityEditScreen({super.key, required this.venueId, required this.facilityId});

  @override
  ConsumerState<FacilityEditScreen> createState() => _FacilityEditScreenState();
}

class _FacilityEditScreenState extends ConsumerState<FacilityEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  FacilityStatus? _status;
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFacility();
  }

  Future<void> _loadFacility() async {
    final repo = ref.read(venueOperatorRepositoryProvider);
    final facility = await repo.getFacility(widget.venueId, widget.facilityId);
    if (facility != null) {
      _nameController = TextEditingController(text: facility.name);
      _descController = TextEditingController(text: facility.description);
      _status = facility.status;
    } else {
      _nameController = TextEditingController();
      _descController = TextEditingController();
    }
    setState(() => _isLoading = false);
  }

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
      
      await apiClient.patch(
        '/organizations/$orgId/venues/${widget.venueId}/facilities/${widget.facilityId}',
        data: {
          'name': _nameController.text,
          'description': _descController.text,
          'status': _status?.name.toUpperCase(),
        },
      );

      if (mounted) context.pop();
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
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Facility')),
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
            DropdownButtonFormField<FacilityStatus>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: FacilityStatus.values.map((s) => DropdownMenuItem(
                value: s,
                child: Text(s.name.toUpperCase()),
              )).toList(),
              onChanged: (v) => setState(() => _status = v),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving ? const CircularProgressIndicator() : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
