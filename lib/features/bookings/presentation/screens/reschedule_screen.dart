import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/booking_provider.dart';
import '../../../availability/presentation/providers/availability_provider.dart';

class RescheduleScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String facilityId;

  const RescheduleScreen({
    super.key,
    required this.bookingId,
    required this.facilityId,
  });

  @override
  ConsumerState<RescheduleScreen> createState() => _RescheduleScreenState();
}

class _RescheduleScreenState extends ConsumerState<RescheduleScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  Future<void> _reschedule(DateTime start, DateTime end) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = ref.read(bookingRepositoryProvider);
      final booking = await repository.rescheduleBooking(
        bookingId: widget.bookingId,
        newStartTime: start,
        newEndTime: end,
      );

      if (mounted) {
        if (booking != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking rescheduled successfully!')),
          );
          context.pop(); // Go back to details
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _selectedDate.toIso8601String().split('T')[0];
    final availabilityAsync = ref.watch(availabilityFutureProvider(
      AvailabilityQuery(facilityId: widget.facilityId, date: dateStr),
    ));

    return Scaffold(
      appBar: AppBar(title: const Text('Reschedule Booking')),
      body: Column(
        children: [
          CalendarDatePicker(
            initialDate: _selectedDate,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 30)),
            onDateChanged: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
          ),
          const Divider(),
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          Expanded(
            child: availabilityAsync.when(
              data: (availability) {
                if (availability == null || availability.slots.isEmpty) {
                  return const Center(child: Text('No slots available for this date.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: availability.slots.length,
                  itemBuilder: (context, index) {
                    final slot = availability.slots[index];
                    final timeStr = '${slot.start.hour.toString().padLeft(2, '0')}:${slot.start.minute.toString().padLeft(2, '0')}';
                    
                    return Card(
                      child: ListTile(
                        title: Text('Start at $timeStr'),
                        trailing: ElevatedButton(
                          onPressed: _isSubmitting ? null : () => _reschedule(slot.start, slot.end),
                          child: const Text('Select'),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
