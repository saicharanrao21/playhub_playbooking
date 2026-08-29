import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';
import '../../../../core/providers/repository_providers.dart';

class AdminPartnerDetailsScreen extends ConsumerStatefulWidget {
  final String partnerId;
  const AdminPartnerDetailsScreen({super.key, required this.partnerId});

  @override
  ConsumerState<AdminPartnerDetailsScreen> createState() => _AdminPartnerDetailsScreenState();
}

class _AdminPartnerDetailsScreenState extends ConsumerState<AdminPartnerDetailsScreen> {
  bool _isProcessing = false;

  Future<void> _reviewPartner(String status) async {
    setState(() => _isProcessing = true);
    final success = await ref.read(adminRepositoryProvider).reviewPartner(widget.partnerId, status);
    
    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Partner set to $status')));
        ref.invalidate(adminPartnerDetailsProvider(widget.partnerId));
        ref.invalidate(adminPartnersProvider(null));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update partner.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailsAsync = ref.watch(adminPartnerDetailsProvider(widget.partnerId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Partner Detail Review')),
      body: detailsAsync.when(
        data: (data) {
          if (data == null) return const Center(child: Text('Partner not found'));
          
          final businesses = data['businesses'] as List? ?? [];
          final memberships = data['memberships'] as List? ?? [];
          final owner = memberships.isNotEmpty ? memberships.first['user'] : null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(data, theme),
                const SizedBox(height: 24),
                _buildOwnerSection(owner, theme),
                const SizedBox(height: 24),
                _buildKYCSection(data, theme),
                const SizedBox(height: 24),
                _buildBusinessList(businesses, theme),
        const SizedBox(height: 40),
                if (_isProcessing)
                  const Center(child: CircularProgressIndicator())
                else
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _reviewPartner('APPROVED'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          child: const Text('Approve KYC & Activate'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _reviewPartner('REJECTED'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Reject Application'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> data, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(data['name'] ?? '', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Status: ${data['status']} • KYC: ${data['kycStatus']}', style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildOwnerSection(dynamic owner, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Primary Owner', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(owner?['fullName'] ?? 'N/A'),
            subtitle: Text(owner?['email'] ?? 'N/A'),
          ),
        ),
      ],
    );
  }

  Widget _buildKYCSection(Map<String, dynamic> data, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('KYC & Banking Information', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildInfoRow('PAN Number', data['panNumber'] ?? 'N/A'),
                const Divider(),
                _buildInfoRow('GST Number', data['gstNumber'] ?? 'N/A'),
                const Divider(),
                _buildInfoRow('Bank Name', data['bankName'] ?? 'N/A'),
                const Divider(),
                _buildInfoRow('Account Holder', data['accountHolderName'] ?? 'N/A'),
                const Divider(),
                _buildInfoRow('Account Number', _maskAccountNumber(data['accountNumber'])),
                const Divider(),
                _buildInfoRow('IFSC Code', data['ifscCode'] ?? 'N/A'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessList(List<dynamic> businesses, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Business Entities', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...businesses.map((b) => Card(
          child: ListTile(
            title: Text(b['displayName'] ?? ''),
            subtitle: Text('Status: ${b['status']}'),
            trailing: const Icon(Icons.business),
          ),
        )),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _maskAccountNumber(String? num) {
    if (num == null || num.length < 4) return 'N/A';
    return 'XXXXXX${num.substring(num.length - 4)}';
  }
}
