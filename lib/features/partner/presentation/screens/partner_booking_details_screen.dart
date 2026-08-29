import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/partner_providers.dart';

class PartnerBookingDetailsScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const PartnerBookingDetailsScreen({super.key, required this.bookingId});

  @override
  ConsumerState<PartnerBookingDetailsScreen> createState() => _PartnerBookingDetailsScreenState();
}

class _PartnerBookingDetailsScreenState extends ConsumerState<PartnerBookingDetailsScreen> {
  bool _isProcessing = false;

  Future<void> _handleAction(Future<void> Function() action, String successMsg) async {
    setState(() => _isProcessing = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(successMsg)));
        ref.invalidate(partnerBookingsProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(partnerBookingDetailsProvider(widget.bookingId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: bookingAsync.when(
        data: (booking) {
          if (booking == null) return const Center(child: Text('Booking not found'));

          final isPending = booking.status == 'PENDING';
          final isConfirmed = booking.status == 'CONFIRMED';
          final isCheckedIn = booking.status == 'CHECKED_IN';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(booking.status).withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    booking.status,
                    style: TextStyle(color: _getStatusColor(booking.status), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),

                // Main Info Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDetailRow(Icons.person_outline, 'Customer', booking.customerName),
                        const Divider(height: 24),
                        _buildDetailRow(Icons.phone_outlined, 'Contact', booking.customerPhone),
                        const Divider(height: 24),
                        _buildDetailRow(Icons.stadium_outlined, 'Facility', booking.facilityName),
                        const Divider(height: 24),
                        _buildDetailRow(Icons.calendar_today_outlined, 'Date', DateFormat('EEEE, MMM d, yyyy').format(booking.startTime)),
                        const Divider(height: 24),
                        _buildDetailRow(Icons.access_time, 'Time', '${DateFormat('h:mm a').format(booking.startTime)} - ${DateFormat('h:mm a').format(booking.endTime)}'),
                        const Divider(height: 24),
                        _buildDetailRow(Icons.payments_outlined, 'Amount', '₹${booking.totalPrice.toStringAsFixed(2)} (${booking.paymentStatus})'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                if (_isProcessing)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  if (isPending) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleAction(
                              () => ref.read(partnerRepositoryProvider).acceptBooking(booking.organizationId, booking.id),
                              'Booking Approved!',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Approve Booking', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleAction(
                              () => ref.read(partnerRepositoryProvider).rejectBooking(booking.organizationId, booking.id, 'Facility unavailable'),
                              'Booking Rejected',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('Reject'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (isConfirmed) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/partner/bookings/scanner'),
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Scan QR to Check-in'),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleAction(
                              () => ref.read(partnerRepositoryProvider).markNoShow(booking.organizationId, booking.id),
                              'Marked as No-Show',
                            ),
                            child: const Text('Mark No-Show'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _handleAction(
                              () => ref.read(partnerRepositoryProvider).completeBooking(booking.organizationId, booking.id),
                              'Booking Completed',
                            ),
                            child: const Text('Force Complete'),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (isCheckedIn) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _handleAction(
                          () => ref.read(partnerRepositoryProvider).completeBooking(booking.organizationId, booking.id),
                          'Booking Completed',
                        ),
                        style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary, foregroundColor: colorScheme.onPrimary),
                        child: const Text('Mark Completed'),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueGrey),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return Colors.orange;
      case 'CONFIRMED': return Colors.green;
      case 'CHECKED_IN': return Colors.blue;
      case 'COMPLETED': return Colors.teal;
      case 'CANCELLED':
      case 'REJECTED': return Colors.red;
      case 'NO_SHOW': return Colors.brown;
      default: return Colors.grey;
    }
  }
}
