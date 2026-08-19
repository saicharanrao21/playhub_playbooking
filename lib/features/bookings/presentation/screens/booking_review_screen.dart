import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/booking_provider.dart';

class BookingReviewScreen extends ConsumerStatefulWidget {
  final String facilityId;
  final String? facilityName;
  final DateTime startTime;
  final DateTime endTime;

  const BookingReviewScreen({
    super.key,
    required this.facilityId,
    this.facilityName,
    required this.startTime,
    required this.endTime,
  });

  @override
  ConsumerState<BookingReviewScreen> createState() => _BookingReviewScreenState();
}

class _BookingReviewScreenState extends ConsumerState<BookingReviewScreen> {
  bool _isSubmitting = false;

  Future<void> _confirmBooking() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = ref.read(bookingRepositoryProvider);
      final booking = await repository.createBooking(
        facilityId: widget.facilityId,
        startTime: widget.startTime,
        endTime: widget.endTime,
      );

      if (mounted) {
        if (booking != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking created successfully!')),
          );
          context.go('/profile'); // Or to "My Bookings"
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create booking.')),
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
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Booking')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Venue & Facility', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Facility: ${widget.facilityName ?? widget.facilityId}'),
            const SizedBox(height: 16),
            const Text('Date & Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Date: ${widget.startTime.toString().split(' ')[0]}'),
            Text('Time: ${widget.startTime.hour.toString().padLeft(2, '0')}:${widget.startTime.minute.toString().padLeft(2, '0')} - ${widget.endTime.hour.toString().padLeft(2, '0')}:${widget.endTime.minute.toString().padLeft(2, '0')}'),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Confirm Booking'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
