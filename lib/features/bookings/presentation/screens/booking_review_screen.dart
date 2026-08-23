import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/booking_provider.dart';
import '../../../payments/data/payment_repository.dart';
import '../../../payments/domain/models/payment_models.dart';
import '../../../../core/security/auth_provider.dart';
import '../../../../app/bootstrap/bootstrap.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final orgId = ref.watch(activeOrganizationProvider) ?? '';
  return PaymentRepository(apiClient, orgId);
});

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
      final bookingRepo = ref.read(bookingRepositoryProvider);
      final paymentRepo = ref.read(paymentRepositoryProvider);
      
      // 1. Create Pending Booking
      final booking = await bookingRepo.createBooking(
        facilityId: widget.facilityId,
        startTime: widget.startTime,
        endTime: widget.endTime,
      );

      if (booking == null) {
        throw Exception('Failed to create booking');
      }

      // 2. Initiate Payment Order
      final order = await paymentRepo.createOrder(booking.id);
      if (order == null) {
        throw Exception('Failed to initiate payment order');
      }

      // 3. Trigger Payment Provider
      if (order.provider == PaymentProvider.mock) {
        final verified = await paymentRepo.verifyPayment(
          providerOrderId: order.id,
          providerPaymentId: 'pay_simulated_${booking.id}',
          signature: 'valid_simulated_sig',
        );

        if (mounted) {
          if (verified) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Booking confirmed successfully!')),
            );
            context.go('/bookings'); 
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment verification failed. Please check your bookings.')),
            );
            context.go('/bookings');
          }
        }
      } else {
        // Real provider flow
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Redirecting to ${order.provider.name.toUpperCase()}...')),
        );
        
        if (mounted) {
          context.go('/bookings');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please complete the payment in the provider popup.')),
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
