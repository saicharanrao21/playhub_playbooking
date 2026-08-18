import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/booking_provider.dart';

class BookingListScreen extends ConsumerWidget {
  const BookingListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(myBookingsProvider.notifier).loadBookings(),
          ),
        ],
      ),
      body: bookingsAsync.when(
        data: (bookings) => bookings.isEmpty
            ? const Center(child: Text('You have no bookings yet.'))
            : ListView.builder(
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text('Booking at Facility: ${booking.facilityId}'),
                      subtitle: Text(
                        '${booking.startTime.toLocal().toString().split('.')[0]} - ${booking.status.name.toUpperCase()}',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/booking/${booking.id}'),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
