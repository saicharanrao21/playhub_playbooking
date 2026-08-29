import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
  String _selectedPaymentMethod = 'UPI';

  Future<void> _confirmBooking() async {
    setState(() => _isSubmitting = true);

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

      try {
        // 2. Initiate Payment Order
        final order = await paymentRepo.createOrder(
          booking.id,
          provider: PaymentProvider.mock,
        );
        if (order != null && order.provider == PaymentProvider.mock) {
          final verified = await paymentRepo.verifyPayment(
            providerOrderId: order.providerOrderId,
            providerPaymentId: 'pay_simulated_${booking.id}',
            signature: 'valid_simulated_sig',
          );
          if (mounted) {
            if (verified) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking confirmed successfully!')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking created (Pending Payment).')),
              );
            }
            context.go('/bookings');
          }
          return;
        }
      } catch (_) {
        // Payment order error / blocked mock in production environment
        // The booking remains safely in PENDING status
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking created! Status: PENDING.')),
        );
        context.go('/bookings');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    final durationHours = widget.endTime.difference(widget.startTime).inMinutes / 60.0;
    const basePrice = 1000.0;
    const taxes = 0.0;
    const total = basePrice + taxes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Confirm', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Venue / Facility Header Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.sports_soccer, color: colorScheme.primary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.facilityName ?? 'Sports Turf',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Facility ID: ${widget.facilityId}',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Booking Schedule Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Schedule & Slot', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildRow(
                      context,
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: dateFormat.format(widget.startTime),
                    ),
                    const Divider(height: 16),
                    _buildRow(
                      context,
                      icon: Icons.schedule,
                      label: 'Time Slot',
                      value: '${timeFormat.format(widget.startTime)} - ${timeFormat.format(widget.endTime)}',
                    ),
                    const Divider(height: 16),
                    _buildRow(
                      context,
                      icon: Icons.timelapse,
                      label: 'Duration',
                      value: '${durationHours.toStringAsFixed(0)} Hour(s)',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Payment Method Selection
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Payment Method', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildPaymentTile(
                      title: 'UPI / Google Pay / PhonePe',
                      subtitle: 'Fast and secure UPI payment',
                      icon: Icons.qr_code_2,
                      value: 'UPI',
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentTile(
                      title: 'PlayHub Wallet',
                      subtitle: 'Available Balance: ₹2,450.00',
                      icon: Icons.account_balance_wallet_outlined,
                      value: 'Wallet',
                    ),
                    const SizedBox(height: 8),
                    _buildPaymentTile(
                      title: 'Credit / Debit Card',
                      subtitle: 'Visa, MasterCard, RuPay',
                      icon: Icons.credit_card,
                      value: 'Card',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Price Breakdown Card
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pricing Breakdown', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Base Slot Price (1 hr)', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        Text('₹${basePrice.toInt()}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Platform / Convenience Fee', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                        const Text('FREE', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount Payable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(
                          '₹${total.toInt()}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: colorScheme.primary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Confirm Booking CTA
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Text(
                        'Confirm & Pay ₹${total.toInt()}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Instant confirmation • Free cancellation up to 2 hours before slot',
                style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, {required IconData icon, required String label, required String value}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildPaymentTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = _selectedPaymentMethod == value;

    return InkWell(
      onTap: () => setState(() => _selectedPaymentMethod = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.3) : colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isSelected ? colorScheme.primary : null)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
