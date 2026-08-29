import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/partner_providers.dart';

class PartnerPricingRuleCreateScreen extends ConsumerStatefulWidget {
  final String facilityId;
  final String facilityName;

  const PartnerPricingRuleCreateScreen({
    super.key,
    required this.facilityId,
    required this.facilityName,
  });

  @override
  ConsumerState<PartnerPricingRuleCreateScreen> createState() => _PartnerPricingRuleCreateScreenState();
}

class _PartnerPricingRuleCreateScreenState extends ConsumerState<PartnerPricingRuleCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameController = TextEditingController(text: 'Peak Hours');
  final _priceController = TextEditingController(text: '800');
  final _priorityController = TextEditingController(text: '10');
  
  TimeOfDay _startTime = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0);
  
  final List<String> _selectedDays = [];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _priorityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = CreatePricingRuleRequest(
        name: _nameController.text.trim(),
        basePrice: double.parse(_priceController.text),
        startTime: '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
        endTime: '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
        daysOfWeek: _selectedDays,
        priority: int.parse(_priorityController.text),
      );

      final repo = ref.read(partnerRepositoryProvider);
      final currentOrg = ref.read(currentPartnerOrgProvider);
      
      await repo.createPricingRule(currentOrg!.id, widget.facilityId, request);

      if (mounted) {
        ref.invalidate(partnerPricingRulesProvider(widget.facilityId));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create rule: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Pricing Rule')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Rule Name (e.g. Peak Hours, Weekend)'),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price per Hour (₹)'),
              validator: (v) => v == null || double.tryParse(v) == null ? 'Invalid price' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    title: const Text('Start Time'),
                    subtitle: Text(_startTime.format(context)),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: _startTime);
                      if (picked != null) setState(() => _startTime = picked);
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('End Time'),
                    subtitle: Text(_endTime.format(context)),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: _endTime);
                      if (picked != null) setState(() => _endTime = picked);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Applicable Days (Empty = All Days)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'].map((day) {
                final isSelected = _selectedDays.contains(day);
                return FilterChip(
                  label: Text(day.substring(0, 3)),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedDays.add(day);
                      } else {
                        _selectedDays.remove(day);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priorityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Priority (Higher values win)'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              child: _isLoading ? const CircularProgressIndicator() : const Text('Save Pricing Rule'),
            ),
          ],
        ),
      ),
    );
  }
}
