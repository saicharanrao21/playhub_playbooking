import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:playhub_playbooking/features/bookings/presentation/providers/booking_provider.dart';
import 'package:playhub_playbooking/features/bookings/domain/models/booking_models.dart';
import 'package:playhub_playbooking/shared/components/empty_view.dart';
import 'package:playhub_playbooking/shared/components/error_view.dart';
import 'package:playhub_playbooking/shared/components/loading_indicator.dart';
import 'package:playhub_playbooking/shared/components/status_badge.dart';

final bookingFilterTabProvider = StateProvider.autoDispose<String>((ref) => 'All');

class BookingListScreen extends ConsumerWidget {
  const BookingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);
    final activeTab = ref.watch(bookingFilterTabProvider);

    final tabs = ['All', 'Confirmed', 'Pending', 'Past / Cancelled'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Bookings',
            onPressed: () => ref.read(myBookingsProvider.notifier).loadBookings(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: tabs.length,
              separatorBuilder: (c, i) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isSelected = activeTab == tab;
                return ChoiceChip(
                  label: Text(tab),
                  selected: isSelected,
                  onSelected: (val) {
                    ref.read(bookingFilterTabProvider.notifier).state = tab;
                  },
                );
              },
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(myBookingsProvider.notifier).loadBookings();
        },
        child: bookingsAsync.when(
          data: (bookings) {
            var filtered = bookings;
            if (activeTab == 'Confirmed') {
              filtered = bookings.where((b) => b.status == BookingStatus.confirmed).toList();
            } else if (activeTab == 'Pending') {
              filtered = bookings.where((b) => b.status == BookingStatus.pending).toList();
            } else if (activeTab == 'Past / Cancelled') {
              filtered = bookings.where((b) => b.status == BookingStatus.cancelled || b.status == BookingStatus.completed).toList();
            }

            if (filtered.isEmpty) {
              return EmptyView(
                icon: Icons.calendar_today_outlined,
                title: 'No bookings found',
                message: activeTab == 'All'
                    ? 'You have not booked any sports venues yet. Explore and book your favorite turf!'
                    : 'No bookings in the "$activeTab" category.',
                actionLabel: 'Explore Venues',
                onAction: () => context.go('/'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final booking = filtered[index];
                return _BookingCard(booking: booking);
              },
            );
          },
          loading: () => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 4,
            itemBuilder: (c, i) => const SkeletonCard(height: 140),
          ),
          error: (err, stack) => AppErrorView(
            message: 'Failed to load bookings: $err',
            onRetry: () => ref.read(myBookingsProvider.notifier).loadBookings(),
          ),
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    final statusName = booking.status.name.toUpperCase();
    final facilityDisplayName = 'Sports Facility: ${booking.facilityId}';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => context.push('/booking/${booking.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Facility Name + Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      facilityDisplayName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusBadge(status: statusName),
                ],
              ),
              const SizedBox(height: 12),

              // Date & Time
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 15, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    dateFormat.format(booking.startTime),
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.schedule, size: 15, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    '${timeFormat.format(booking.startTime)} - ${timeFormat.format(booking.endTime)}',
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Price & Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Amount', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                      Text(
                        '₹${(booking.totalPrice ?? 1000.0).toInt()}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: colorScheme.primary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (booking.status == BookingStatus.confirmed || booking.status == BookingStatus.pending)
                        TextButton(
                          onPressed: () => context.push(
                            '/booking/${booking.id}/reschedule',
                            extra: {'facilityId': booking.facilityId},
                          ),
                          child: const Text('Reschedule'),
                        ),
                      ElevatedButton(
                        onPressed: () => context.push('/booking/${booking.id}'),
                        style: ElevatedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Details'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
