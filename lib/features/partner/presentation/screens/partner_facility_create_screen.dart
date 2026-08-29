import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/repository_providers.dart';
import '../providers/partner_providers.dart';

class PartnerFacilityCreateScreen extends ConsumerStatefulWidget {
  final String venueId;

  const PartnerFacilityCreateScreen({super.key, required this.venueId});

  @override
  ConsumerState<PartnerFacilityCreateScreen> createState() => _PartnerFacilityCreateScreenState();
}

class _PartnerFacilityCreateScreenState extends ConsumerState<PartnerFacilityCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameController = TextEditingController(text: 'Turf Pitch A (Cricket & Football)');
  final _descriptionController = TextEditingController(text: 'Synthetic artificial turf with LED floodlights.');
  final _capacityController = TextEditingController(text: '14');

  String? _selectedCategoryId;
  String _selectedStatus = 'ACTIVE';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _submitFacility() async {
    if (!_formKey.currentState!.validate()) return;

    final currentOrg = ref.read(currentPartnerOrgProvider);
    if (currentOrg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organization context required.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = CreatePartnerFacilityRequest(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        capacity: int.tryParse(_capacityController.text.trim()) ?? 10,
        categoryId: _selectedCategoryId ?? 'cat_cricket',
        status: _selectedStatus,
      );

      final repo = ref.read(partnerRepositoryProvider);
      await repo.createFacility(currentOrg.id, widget.venueId, request);

      ref.invalidate(partnerFacilitiesProvider(widget.venueId));
      ref.invalidate(partnerVenueDetailsProvider(widget.venueId));
      ref.invalidate(partnerStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚽ Court / Facility created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create facility: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Court / Pitch', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Facility Specification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Court / Facility Name *',
                  hintText: 'e.g. Pitch A, Badminton Court 1',
                  prefixIcon: Icon(Icons.sports_tennis),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Surface & Lighting Details',
                  hintText: 'e.g. Wooden indoor court, non-marking shoes required',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Player Capacity *',
                  hintText: 'e.g. 10',
                  prefixIcon: Icon(Icons.people),
                ),
                validator: (v) => v == null || int.tryParse(v.trim()) == null ? 'Enter valid number' : null,
              ),

              const SizedBox(height: 20),
              const Text('Sport Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),

              categoriesAsync.when(
                data: (categories) {
                  if (_selectedCategoryId == null && categories.isNotEmpty) {
                    _selectedCategoryId = categories.first.id;
                  }
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Primary Sport *',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (err, stack) => const Text('Default Category: All Sports'),
              ),

              const SizedBox(height: 20),
              const Text('Initial Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Operating Status *',
                  prefixIcon: Icon(Icons.toggle_on),
                ),
                items: const [
                  DropdownMenuItem(value: 'ACTIVE', child: Text('Active (Available for Booking)')),
                  DropdownMenuItem(value: 'INACTIVE', child: Text('Inactive (Hidden from Customers)')),
                  DropdownMenuItem(value: 'MAINTENANCE', child: Text('Under Maintenance')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedStatus = val);
                },
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitFacility,
                  icon: const Icon(Icons.check_circle_outline),
                  label: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Add Facility to Venue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final categoriesProvider = FutureProvider.autoDispose((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getCategories();
});
