import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:playhub_playbooking/features/bookings/presentation/providers/booking_provider.dart';
import 'package:playhub_playbooking/features/availability/presentation/providers/availability_provider.dart';
import 'package:playhub_playbooking/features/availability/domain/models/availability_models.dart';
import 'package:playhub_playbooking/shared/components/empty_view.dart';
import 'package:playhub_playbooking/shared/components/error_view.dart';
import 'package:playhub_playbooking/shared/components/loading_indicator.dart';

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
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  bool _isSubmitting = false;

  Future<void> _reschedule(DateTime start, DateTime end) async {
    setState(() => _isSubmitting = true);

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
          ref.read(myBookingsProvider.notifier).loadBookings();
          context.pop();
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
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final availabilityAsync = ref.watch(availabilityFutureProvider(
      AvailabilityQuery(facilityId: widget.facilityId, date: dateStr),
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reschedule Booking', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Date Selector Strip
          Container(
            height: 84,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
              border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4))),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 14,
              separatorBuilder: (c, i) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index));
                final isSelected = DateUtils.isSameDay(_selectedDate, date);

                return InkWell(
                  onTap: () => setState(() => _selectedDate = date),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 60,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.primary : colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(date).toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: LinearProgressIndicator(),
            ),

          Expanded(
            child: availabilityAsync.when(
              data: (availability) {
                if (availability == null || availability.slots.isEmpty) {
                  return const EmptyView(
                    icon: Icons.event_busy,
                    title: 'No Available Slots',
                    message: 'Please pick another date to reschedule your booking.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: availability.slots.length,
                  itemBuilder: (context, index) {
                    final slot = availability.slots[index];
                    final timeStr = '${DateFormat('h:mm a').format(slot.startTime)} - ${DateFormat('h:mm a').format(slot.endTime)}';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(Icons.schedule, color: colorScheme.primary, size: 20),
                        ),
                        title: Text(timeStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Available for reschedule', style: TextStyle(fontSize: 12, color: Colors.green)),
                        trailing: ElevatedButton(
                          onPressed: _isSubmitting ? null : () => _reschedule(slot.startTime, slot.endTime),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Confirm'),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 4,
                itemBuilder: (c, i) => const SkeletonCard(height: 70),
              ),
              error: (err, stack) => AppErrorView(
                message: 'Failed to load slots: $err',
                onRetry: () => ref.invalidate(availabilityFutureProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
