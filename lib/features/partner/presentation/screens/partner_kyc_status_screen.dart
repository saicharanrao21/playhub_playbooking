import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/partner_providers.dart';

class PartnerKYCStatusScreen extends ConsumerWidget {
  const PartnerKYCStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentOrg = ref.watch(currentPartnerOrgProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isApproved = currentOrg?.kycStatus == PartnerKYCStatus.approved;
    final isSubmitted = currentOrg?.kycStatus == PartnerKYCStatus.submitted || currentOrg?.kycStatus == PartnerKYCStatus.underReview;
    final isRejected = currentOrg?.kycStatus == PartnerKYCStatus.rejected;
    final isDraft = currentOrg?.kycStatus == PartnerKYCStatus.draft;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner KYC & Compliance', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (isApproved ? Colors.green : (isRejected ? Colors.red : Colors.orange)).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: (isApproved ? Colors.green : (isRejected ? Colors.red : Colors.orange)).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    isApproved ? Icons.verified : (isRejected ? Icons.error_outline : Icons.pending_actions),
                    color: isApproved ? Colors.green : (isRejected ? Colors.red : Colors.orange),
                    size: 40,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentOrg?.kycStatus.label ?? 'Status Unknown',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isApproved ? Colors.green : (isRejected ? Colors.red : Colors.orange),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isApproved 
                              ? 'Your business documents and settlement bank account are active.'
                              : (isDraft ? 'Submit your business details to start verification.' : 'We are reviewing your business documents.'),
                          style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Verification Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildTimelineStep(
                      title: 'Business Registration & Profile',
                      subtitle: 'Legal entity name and physical address verification.',
                      isComplete: !isDraft,
                    ),
                    const Divider(height: 24),
                    _buildTimelineStep(
                      title: 'Tax & Identity (PAN / GSTIN)',
                      subtitle: 'Government credentials validation for sports entertainment.',
                      isComplete: isApproved || isSubmitted,
                    ),
                    const Divider(height: 24),
                    _buildTimelineStep(
                      title: 'Settlement Bank Account',
                      subtitle: 'Penny drop verification and payout enabling.',
                      isComplete: isApproved,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text('Registered Business Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow('Organization', currentOrg?.name ?? 'Skyline Sports Hub'),
                    const Divider(height: 16),
                    _buildInfoRow('Status', currentOrg?.status ?? 'ACTIVE'),
                    if (currentOrg?.panNumber != null) ...[
                      const Divider(height: 16),
                      _buildInfoRow('PAN', currentOrg!.panNumber!),
                    ],
                    if (currentOrg?.bankName != null) ...[
                      const Divider(height: 16),
                      _buildInfoRow('Bank', currentOrg!.bankName!),
                    ],
                    const Divider(height: 16),
                    _buildInfoRow('Settlement Frequency', 'Daily Automated (T+1)'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            if (isDraft || isRejected)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/partner/onboarding'),
                  child: Text(isRejected ? 'Resubmit KYC' : 'Complete Onboarding'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isComplete,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isComplete ? Colors.green : Colors.grey,
          size: 22,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
