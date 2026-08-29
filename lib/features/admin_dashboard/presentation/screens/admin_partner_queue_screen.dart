import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/admin_provider.dart';
import '../../../../shared/components/error_view.dart';

class AdminPartnerQueueScreen extends ConsumerStatefulWidget {
  final String? initialStatus;
  const AdminPartnerQueueScreen({super.key, this.initialStatus});

  @override
  ConsumerState<AdminPartnerQueueScreen> createState() => _AdminPartnerQueueScreenState();
}

class _AdminPartnerQueueScreenState extends ConsumerState<AdminPartnerQueueScreen> {
  late String? _kycFilter;

  @override
  void initState() {
    super.initState();
    _kycFilter = widget.initialStatus ?? 'SUBMITTED';
  }

  @override
  Widget build(BuildContext context) {
    final partnersAsync = ref.watch(adminPartnersProvider(_kycFilter));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Applications', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          DropdownButton<String?>(
            value: _kycFilter,
            dropdownColor: theme.colorScheme.surface,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: null, child: Text('All')),
              DropdownMenuItem(value: 'SUBMITTED', child: Text('Pending Review')),
              DropdownMenuItem(value: 'APPROVED', child: Text('Approved')),
              DropdownMenuItem(value: 'REJECTED', child: Text('Rejected')),
            ],
            onChanged: (val) => setState(() => _kycFilter = val),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: partnersAsync.when(
        data: (partners) {
          if (partners.isEmpty) {
            return const Center(child: Text('No partner applications found for this filter.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: partners.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final partner = partners[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(partner.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Owner: ${partner.ownerName ?? partner.ownerEmail ?? "N/A"}'),
                      Text('Submitted: ${DateFormat('MMM dd, yyyy').format(partner.createdAt)}'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getKYCColor(partner.kycStatus).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          partner.kycStatus,
                          style: TextStyle(color: _getKYCColor(partner.kycStatus), fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/admin-dashboard/partners/${partner.id}'),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => AppErrorView(message: err.toString(), onRetry: () => ref.refresh(adminPartnersProvider(_kycFilter))),
      ),
    );
  }

  Color _getKYCColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED': return Colors.green;
      case 'SUBMITTED':
      case 'UNDER_REVIEW': return Colors.orange;
      case 'REJECTED': return Colors.red;
      default: return Colors.grey;
    }
  }
}
