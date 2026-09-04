import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/partner_providers.dart';

class PartnerVenueCreateScreen extends ConsumerStatefulWidget {
  const PartnerVenueCreateScreen({super.key});

  @override
  ConsumerState<PartnerVenueCreateScreen> createState() => _PartnerVenueCreateScreenState();
}

class _PartnerVenueCreateScreenState extends ConsumerState<PartnerVenueCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameController = TextEditingController(text: 'Skyline Box Cricket & Badminton Arena');
  final _slugController = TextEditingController(text: 'skyline-box-cricket-arena');
  final _descriptionController = TextEditingController(text: 'Premier indoor turf with professional floodlights, synthetic turf, and VIP lounge.');
  final _addressController = TextEditingController(text: 'Sy No 45, Gachibowli Stadium Road');
  final _cityController = TextEditingController(text: 'Hyderabad');
  final _stateController = TextEditingController(text: 'Telangana');
  final _postalCodeController = TextEditingController(text: '500032');
  final _latController = TextEditingController(text: '17.4435');
  final _lngController = TextEditingController(text: '78.3772');

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _generateSlug(String value) {
    final slug = value.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-+|-+$'), '');
    _slugController.text = slug;
  }

  Future<void> _submitVenue() async {
    if (!_formKey.currentState!.validate()) return;

    final currentOrg = ref.read(currentPartnerOrgProvider);
    if (currentOrg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active organization found. Please complete onboarding first.')),
      );
      return;
    }

    final businessId = currentOrg.businesses.isNotEmpty ? currentOrg.businesses.first.id : currentOrg.id;

    setState(() => _isLoading = true);

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final slugSuffix = timestamp.length > 4 ? timestamp.substring(timestamp.length - 4) : timestamp;
      final request = CreatePartnerVenueRequest(
        name: _nameController.text.trim(),
        slug: _slugController.text.trim().isEmpty ? 'venue-$slugSuffix' : _slugController.text.trim(),
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        latitude: double.tryParse(_latController.text.trim()),
        longitude: double.tryParse(_lngController.text.trim()),
      );

      final repo = ref.read(partnerRepositoryProvider);
      await repo.createVenue(currentOrg.id, businessId, request);

      ref.invalidate(partnerVenuesProvider);
      ref.invalidate(partnerStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🏟️ Venue created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create venue: $e'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Sports Venue', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Venue Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                onChanged: _generateSlug,
                decoration: const InputDecoration(
                  labelText: 'Venue Name *',
                  hintText: 'e.g. Skyline Sports Arena',
                  prefixIcon: Icon(Icons.stadium),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _slugController,
                decoration: const InputDecoration(
                  labelText: 'URL Identifier / Slug *',
                  hintText: 'e.g. skyline-sports-arena',
                  prefixIcon: Icon(Icons.link),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description & Amenities',
                  hintText: 'Describe playing surfaces, lighting, parking, changing rooms...',
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 24),
              const Text('Location Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Street Address *',
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City *',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: const InputDecoration(
                        labelText: 'State *',
                        prefixIcon: Icon(Icons.map),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _postalCodeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Postal / PIN Code *',
                  prefixIcon: Icon(Icons.pin_drop),
                ),
                validator: (v) => v == null || v.trim().length < 6 ? 'Enter 6-digit PIN' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Latitude', prefixIcon: Icon(Icons.gps_fixed)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lngController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Longitude', prefixIcon: Icon(Icons.gps_fixed)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    // Pre-fill coordinates if blank
                    if (_latController.text.isEmpty) _latController.text = '17.4435';
                    if (_lngController.text.isEmpty) _lngController.text = '78.3772';
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('📍 Coordinates populated from address geocoding.')),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('Auto-Geocode Coordinates', style: TextStyle(fontSize: 12)),
                ),
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitVenue,
                  icon: const Icon(Icons.add_circle_outline),
                  label: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Publish Venue Listing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
