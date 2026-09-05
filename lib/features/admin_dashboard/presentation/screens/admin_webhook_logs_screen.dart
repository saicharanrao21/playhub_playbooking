import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/admin_webhooks_provider.dart';
import '../../../../app/bootstrap/bootstrap.dart';

class AdminWebhookLogsScreen extends ConsumerStatefulWidget {
  const AdminWebhookLogsScreen({super.key});

  @override
  ConsumerState<AdminWebhookLogsScreen> createState() => _AdminWebhookLogsScreenState();
}

class _AdminWebhookLogsScreenState extends ConsumerState<AdminWebhookLogsScreen> {
  String? _statusFilter;
  String? _providerFilter;

  Future<void> _showWebhookDetail(String id) async {
    final apiClient = ref.read(apiClientProvider);
    final response = await apiClient.get<Map<String, dynamic>>('/admin/webhooks/$id');

    if (!mounted) return;

    if (!response.isSuccess || response.data == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load webhook details')));
      return;
    }

    final data = response.data!;
    final isFailed = data['status'] == 'FAILED';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              data['provider'] == 'RAZORPAY' ? Icons.payment : Icons.credit_card,
              color: Colors.indigo,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${data['provider']} • ${data['eventType']}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Event ID', data['providerEventId'] ?? 'N/A'),
              _buildDetailRow('Status', data['status'] ?? 'N/A'),
              _buildDetailRow('Payment ID', data['paymentId'] ?? 'N/A'),
              _buildDetailRow('Org ID', data['organizationId'] ?? 'N/A'),
              _buildDetailRow('Retry Count', '${data['retryCount'] ?? 0}'),
              if (data['lastError'] != null)
                _buildDetailRow('Last Error', data['lastError'], isError: true),
              const SizedBox(height: 12),
              const Text('Payload:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data['payload'] != null ? data['payload'].toString() : '{}',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          if (isFailed || data['status'] == 'IGNORED')
            ElevatedButton.icon(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);
                nav.pop();

                final retryRes = await apiClient.post('/admin/webhooks/$id/retry');
                if (mounted) {
                  if (retryRes.isSuccess) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('🎉 Webhook event requeued for processing!'), backgroundColor: Colors.green),
                    );
                    ref.invalidate(adminWebhookLogsProvider(const {}));
                  } else {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Failed to retry webhook event'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry Webhook'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, String> query = {};
    if (_statusFilter != null) query['status'] = _statusFilter!;
    if (_providerFilter != null) query['provider'] = _providerFilter!;

    final logsAsync = ref.watch(adminWebhookLogsProvider(query));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gateway Webhook Operations', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminWebhookLogsProvider(query)),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  DropdownButton<String?>(
                    value: _statusFilter,
                    hint: const Text('All Statuses'),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Statuses')),
                      DropdownMenuItem(value: 'QUEUED', child: Text('QUEUED')),
                      DropdownMenuItem(value: 'PROCESSING', child: Text('PROCESSING')),
                      DropdownMenuItem(value: 'PROCESSED', child: Text('PROCESSED')),
                      DropdownMenuItem(value: 'FAILED', child: Text('FAILED')),
                      DropdownMenuItem(value: 'IGNORED', child: Text('IGNORED')),
                    ],
                    onChanged: (val) => setState(() => _statusFilter = val),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String?>(
                    value: _providerFilter,
                    hint: const Text('All Providers'),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Providers')),
                      DropdownMenuItem(value: 'RAZORPAY', child: Text('Razorpay')),
                      DropdownMenuItem(value: 'STRIPE', child: Text('Stripe')),
                    ],
                    onChanged: (val) => setState(() => _providerFilter = val),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: logsAsync.when(
              data: (data) {
                if (data == null || (data['items'] as List).isEmpty) {
                  return const Center(child: Text('No webhook logs recorded.'));
                }

                final items = data['items'] as List;

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final log = items[index] as Map<String, dynamic>;
                    final status = log['status'] ?? 'RECEIVED';
                    final isSuccess = status == 'PROCESSED';
                    final isFailed = status == 'FAILED';

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      leading: CircleAvatar(
                        backgroundColor: isSuccess
                            ? Colors.green.withValues(alpha: 0.15)
                            : (isFailed ? Colors.red.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15)),
                        child: Icon(
                          log['provider'] == 'RAZORPAY' ? Icons.payment : Icons.credit_card,
                          color: isSuccess ? Colors.green : (isFailed ? Colors.red : Colors.orange),
                          size: 18,
                        ),
                      ),
                      title: Text(
                        '${log['provider']} • ${log['eventType']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Text(
                        'ID: ${log['providerEventId']} • ${DateFormat('MMM dd, HH:mm:ss').format(DateTime.parse(log['createdAt']))}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Chip(
                        label: Text(status, style: TextStyle(fontSize: 10, color: isSuccess ? Colors.white : Colors.black87)),
                        backgroundColor: isSuccess ? Colors.green : (isFailed ? Colors.red.shade200 : Colors.orange.shade100),
                      ),
                      onTap: () => _showWebhookDetail(log['id']),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading webhooks: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11))),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: isError ? Colors.red : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
