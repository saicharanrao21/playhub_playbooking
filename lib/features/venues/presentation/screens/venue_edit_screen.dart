import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../domain/models/venue_models.dart';
import 'package:go_router/go_router.dart';

class VenueEditScreen extends ConsumerStatefulWidget {
  final String venueId;
  const VenueEditScreen({super.key, required this.venueId});

  @override
  ConsumerState<VenueEditScreen> createState() => _VenueEditScreenState();
}

class _VenueEditScreenState extends ConsumerState<VenueEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _descController;
  String? _selectedCityId;
  VenueStatus? _status;
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVenue();
  }

  Future<void> _loadVenue() async {
    final repo = ref.read(venueOperatorRepositoryProvider);
    final venue = await repo.getVenue(widget.venueId);
    if (venue != null) {
      _nameController = TextEditingController(text: venue.name);
      _addressController = TextEditingController(text: venue.address);
      _descController = TextEditingController(text: venue.description);
      _selectedCityId = venue.cityId;
      _status = venue.status;
    } else {
       _nameController = TextEditingController();
       _addressController = TextEditingController();
       _descController = TextEditingController();
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(venueOperatorRepositoryProvider);
      await repo.updateVenue(widget.venueId, {
        'name': _nameController.text,
        'address': _addressController.text,
        'description': _descController.text,
        'cityId': _selectedCityId,
        'status': _status?.name.toUpperCase(),
      });

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
      appBar: AppBar(title: const Text('Edit Venue')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Venue Name'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            DropdownButtonFormField<VenueStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: VenueStatus.values.map((s) => DropdownMenuItem(
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
