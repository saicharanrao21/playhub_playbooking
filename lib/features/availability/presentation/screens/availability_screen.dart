import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/availability_provider.dart';

class AvailabilityScreen extends ConsumerStatefulWidget {
  final String facilityId;
  final String? facilityName;
  const AvailabilityScreen({super.key, required this.facilityId, this.facilityName});

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final dateStr = _selectedDate.toIso8601String().split('T')[0];
    final availabilityAsync = ref.watch(availabilityFutureProvider(
      AvailabilityQuery(facilityId: widget.facilityId, date: dateStr),
    ));

    return Scaffold(
      appBar: AppBar(title: const Text('Select Time Slot')),
      body: Column(
        children: [
          CalendarDatePicker(
            initialDate: _selectedDate,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().plus(const Duration(days: 30)),
            onDateChanged: (date) {
              setState(() {
                _selectedDate = date;
              });
            },
          ),
          const Divider(),
          Expanded(
            child: availabilityAsync.when(
              data: (availability) {
                if (availability == null || availability.slots.isEmpty) {
                  return const Center(child: Text('No slots available for this date.'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: availability.slots.length,
                  itemBuilder: (context, index) {
                    final slot = availability.slots[index];
                    final startTimeStr = '${slot.start.hour.toString().padLeft(2, '0')}:${slot.start.minute.toString().padLeft(2, '0')}';
                    return ElevatedButton(
                      onPressed: () {
                         // Navigate to Review Screen
                         context.push('/booking/review', extra: {
                           'facilityId': widget.facilityId,
                           'facilityName': widget.facilityName,
                           'startTime': slot.start.toIso8601String(),
                           'endTime': slot.end.toIso8601String(),
                         });
                      },
                      child: Text(startTimeStr),
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

extension on DateTime {
  DateTime plus(Duration duration) => add(duration);
}
