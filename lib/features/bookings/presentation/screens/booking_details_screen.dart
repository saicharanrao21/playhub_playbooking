import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/booking_provider.dart';
import '../../domain/models/booking_models.dart';
import '../../../../core/models/app_models.dart' hide Booking, BookingStatus;
import '../../../../core/security/auth_provider.dart';
import '../../../../core/security/permissions.dart';

class BookingDetailsScreen extends ConsumerStatefulWidget {
  final String bookingId;
  const BookingDetailsScreen({super.key, required this.bookingId});

  @override
  ConsumerState<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends ConsumerState<BookingDetailsScreen> {
  Booking? _booking;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final repository = ref.read(bookingRepositoryProvider);
      final booking = await repository.getBooking(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = booking;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelBooking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(myBookingsProvider.notifier).cancelBooking(widget.bookingId);
        _loadBooking(); // Reload details to reflect cancelled status
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: Center(child: Text(_error ?? 'Booking not found')),
      );
    }

    final booking = _booking!;

    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking ID: ${booking.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('Status: ${booking.status.name.toUpperCase()}'),
            const SizedBox(height: 8),
            Text('Start: ${booking.startTime.toLocal().toString().split('.')[0]}'),
            const SizedBox(height: 8),
            Text('End: ${booking.endTime.toLocal().toString().split('.')[0]}'),
            const SizedBox(height: 32),
            if (booking.status != BookingStatus.cancelled) ...[
              if (ref.hasRole(UserRole.customer) || ref.can(AppPermissions.bookingUpdate))
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.push(
                      '/booking/${booking.id}/reschedule',
                      extra: {'facilityId': booking.facilityId},
                    ),
                    child: const Text('Reschedule Booking'),
                  ),
                ),
              if (ref.hasRole(UserRole.customer) || ref.can(AppPermissions.bookingUpdate))
                const SizedBox(height: 12),
              if (ref.hasRole(UserRole.customer) || ref.can(AppPermissions.bookingDelete))
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _cancelBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Cancel Booking'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
