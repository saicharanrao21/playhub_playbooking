import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:playhub_playbooking/app/bootstrap/bootstrap.dart';
import '../providers/support_provider.dart';

class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  void _openContactForm() {
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'BOOKING_ISSUE';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          top: 24,
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Submit Support Ticket',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(labelText: 'Issue Category'),
                items: const [
                  DropdownMenuItem(value: 'BOOKING_ISSUE', child: Text('Booking / Slot Issue')),
                  DropdownMenuItem(value: 'PAYMENT_ISSUE', child: Text('Payment & Checkout')),
                  DropdownMenuItem(value: 'REFUND_ISSUE', child: Text('Refund & Dispute')),
                  DropdownMenuItem(value: 'VENUE_ISSUE', child: Text('Venue & Facilities')),
                  DropdownMenuItem(value: 'TECHNICAL_ISSUE', child: Text('Technical / App Issue')),
                  DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                ],
                onChanged: (v) {
                  if (v != null) selectedCategory = v;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: 'Subject'),
                validator: (v) => v == null || v.trim().length < 5 ? 'Please enter a subject (min 5 chars)' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Describe your issue in detail',
                  alignLabelWithHint: true,
                ),
                validator: (v) => v == null || v.trim().length < 10
                    ? 'Please provide at least 10 characters'
                    : null,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final messenger = ScaffoldMessenger.of(context);
                      final nav = Navigator.of(context);
                      nav.pop();

                      final apiClient = ref.read(apiClientProvider);
                      final response = await apiClient.post('/support/tickets', data: {
                        'category': selectedCategory,
                        'subject': subjectController.text.trim(),
                        'description': descriptionController.text.trim(),
                      });

                      if (mounted) {
                        if (response.isSuccess) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('🎉 Support ticket created successfully!'), backgroundColor: Colors.green),
                          );
                          ref.invalidate(mySupportTicketsProvider);
                        } else {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Failed to submit support ticket.'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Submit Ticket'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTicketDetails(Map<String, dynamic> ticket) {
    final status = ticket['status'] ?? 'OPEN';
    final isClosed = status == 'RESOLVED' || status == 'CLOSED';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${ticket['subject']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    label: Text(status, style: const TextStyle(fontSize: 10, color: Colors.white)),
                    backgroundColor: isClosed ? Colors.green : Colors.orange,
                  ),
                  Text(
                    DateFormat('MMM dd, yyyy').format(DateTime.parse(ticket['createdAt'])),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Category:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text(ticket['category'] ?? 'OTHER', style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text(ticket['description'] ?? '', style: const TextStyle(fontSize: 12)),
              if (ticket['resolutionNotes'] != null) ...[
                const SizedBox(height: 12),
                const Text('Resolution Notes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                Text(ticket['resolutionNotes'], style: const TextStyle(fontSize: 12, color: Colors.green)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ticketsAsync = ref.watch(mySupportTicketsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(mySupportTicketsProvider),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Support Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colorScheme.primaryContainer, colorScheme.surfaceContainerHighest],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How can we help you today?',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Our support team and venue liaisons are available 24/7.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.support_agent, size: 18),
                          label: const Text('New Ticket'),
                          onPressed: _openContactForm,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // My Support Tickets Section
            Text(
              'My Support Cases',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ticketsAsync.when(
              data: (data) {
                final items = data?['items'] as List? ?? [];
                if (items.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No support tickets submitted.'),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final ticket = items[index] as Map<String, dynamic>;
                    final status = ticket['status'] ?? 'OPEN';
                    final isClosed = status == 'RESOLVED' || status == 'CLOSED';

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: isClosed ? Colors.green.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
                        child: Icon(Icons.confirmation_number_outlined, color: isClosed ? Colors.green : Colors.orange, size: 18),
                      ),
                      title: Text(ticket['subject'] ?? 'Ticket', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('${ticket['category']} • ${DateFormat('MMM dd').format(DateTime.parse(ticket['createdAt']))}'),
                      trailing: Chip(
                        label: Text(status, style: TextStyle(fontSize: 10, color: isClosed ? Colors.white : Colors.black87)),
                        backgroundColor: isClosed ? Colors.green : Colors.orange.shade100,
                      ),
                      onTap: () => _showTicketDetails(ticket),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error loading tickets: $e'),
            ),

            const SizedBox(height: 24),

            // FAQs
            Text(
              'Frequently Asked Questions',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Column(
                children: [
                  ExpansionTile(
                    leading: Icon(Icons.help_outline),
                    title: Text('How do I cancel or reschedule a booking?'),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'You can reschedule your slot up to 2 hours before start time directly from "My Bookings" > Booking Details > Reschedule. Cancellation refunds are credited immediately to your PlayHub Wallet.',
                          style: TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 1),
                  ExpansionTile(
                    leading: Icon(Icons.account_balance_wallet_outlined),
                    title: Text('How does PlayHub Wallet work?'),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'PlayHub Wallet allows instant 1-click checkout with zero payment gateway drop-offs. You can top up anytime via UPI or Cards and earn promotional reward points on every transaction.',
                          style: TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 1),
                  ExpansionTile(
                    leading: Icon(Icons.sports_soccer_outlined),
                    title: Text('How do I join or host matches?'),
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'Browse open games on the "Matches" tab and tap "Join Match". To organize your own game, tap "Host Match", select the sport, time, venue, and per-player split fee.',
                          style: TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Contact Details
            Text(
              'Direct Support Channels',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email Support'),
                    subtitle: const Text('support@playhub.com'),
                    trailing: const Icon(Icons.open_in_new, size: 18),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Email: support@playhub.com')),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.phone_outlined),
                    title: const Text('Helpline (Mon - Sun, 6 AM - 11 PM)'),
                    subtitle: const Text('+91 1800-PLAY-HUB'),
                    trailing: const Icon(Icons.call, size: 18),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Calling +91 1800-PLAY-HUB...')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
