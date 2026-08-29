import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:playhub_playbooking/core/repositories/match_repository.dart';

class HostMatchScreen extends ConsumerStatefulWidget {
  const HostMatchScreen({super.key});

  @override
  ConsumerState<HostMatchScreen> createState() => _HostMatchScreenState();
}

class _HostMatchScreenState extends ConsumerState<HostMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _venueController = TextEditingController(text: 'Skyline Sports Arena, Hyderabad');
  final _locationController = TextEditingController(text: 'Madhapur, Hyderabad');
  final _priceController = TextEditingController(text: '200');
  final _descriptionController = TextEditingController();

  String _sport = 'Football';
  int _maxPlayers = 10;
  String _skillLevel = 'All Levels';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  final int _durationHours = 2;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _venueController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(matchRepositoryProvider);

      final startDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      final endDateTime = startDateTime.add(Duration(hours: _durationHours));
      final price = double.tryParse(_priceController.text) ?? 150.0;

      final success = await repo.hostMatch(
        title: _titleController.text.trim(),
        sport: _sport,
        maxPlayers: _maxPlayers,
        startTime: startDateTime,
        endTime: endDateTime,
        pricePerPlayer: price,
        venueName: _venueController.text.trim(),
        location: _locationController.text.trim(),
        description: _descriptionController.text.trim(),
        skillLevel: _skillLevel,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Match hosted successfully! Players can now join.')),
          );
          context.pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to host match. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('EEE, MMM d, yyyy');

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: const Text('Host a Match', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Match Information',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Match Title *',
                hintText: 'e.g. Sunday 5-a-side Football Friendly',
                prefixIcon: Icon(Icons.sports_score),
              ),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter a match title' : null,
            ),
            const SizedBox(height: 16),

            // Sport Dropdown
            DropdownButtonFormField<String>(
              initialValue: _sport,
              decoration: const InputDecoration(
                labelText: 'Sport *',
                prefixIcon: Icon(Icons.sports),
              ),
              items: ['Football', 'Cricket', 'Badminton', 'Tennis', 'Basketball', 'Swimming']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _sport = val);
              },
            ),
            const SizedBox(height: 16),

            // Venue Name & Location
            TextFormField(
              controller: _venueController,
              decoration: const InputDecoration(
                labelText: 'Venue Name *',
                hintText: 'e.g. Skyline Sports Turf',
                prefixIcon: Icon(Icons.stadium_outlined),
              ),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter venue name' : null,
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location / City *',
                hintText: 'e.g. Madhapur, Hyderabad',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (val) => (val == null || val.trim().isEmpty) ? 'Please enter location' : null,
            ),
            const SizedBox(height: 24),

            Text(
              'Schedule & Capacity',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Date Picker Tile
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              leading: Icon(Icons.calendar_today, color: colorScheme.primary),
              title: const Text('Match Date'),
              subtitle: Text(dateFormat.format(_selectedDate)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 60)),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
            ),
            const SizedBox(height: 12),

            // Time Picker Tile
            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: colorScheme.outlineVariant),
              ),
              leading: Icon(Icons.access_time, color: colorScheme.primary),
              title: const Text('Start Time'),
              subtitle: Text(_selectedTime.format(context)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (time != null) setState(() => _selectedTime = time);
              },
            ),
            const SizedBox(height: 16),

            // Max Players & Skill Level
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: _maxPlayers,
                    decoration: const InputDecoration(labelText: 'Max Players'),
                    items: [2, 4, 6, 8, 10, 11, 14, 16, 22]
                        .map((n) => DropdownMenuItem(value: n, child: Text('$n players')))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _maxPlayers = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _skillLevel,
                    decoration: const InputDecoration(labelText: 'Skill Level'),
                    items: ['All Levels', 'Beginner', 'Intermediate', 'Advanced']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _skillLevel = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Price per player
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price per Player (₹) *',
                prefixText: '₹ ',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              keyboardType: TextInputType.number,
              validator: (val) {
                if (val == null || val.isEmpty) return 'Please enter price';
                if (double.tryParse(val) == null) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Rules & Description (Optional)',
                hintText: 'e.g. Non-marking shoes mandatory, refreshments provided...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Create & Publish Match', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
