import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/security/auth_provider.dart';
import '../providers/partner_providers.dart';

class PartnerEntryScreen extends ConsumerWidget {
  const PartnerEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final orgsAsync = ref.watch(myPartnerOrganizationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PlayHub Partner Portal', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
        ),
      ),
      body: authState.identity == null
          ? _buildLoginRequired(context)
          : orgsAsync.when(
              data: (orgs) {
                if (orgs.isEmpty) {
                  return _buildOnboardingIntro(context);
                }
                return _buildPartnerWorkspaceLauncher(context, ref, orgs);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => _buildOnboardingIntro(context),
            ),
    );
  }

  Widget _buildLoginRequired(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Authentication Required',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please log in to your PlayHub account to access the partner portal or register your sports business.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              child: const Text('Log In to Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingIntro(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PLAYHUB FOR BUSINESS',
                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'List Your Venue.\nMaximize Your Bookings.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join India’s fastest growing sports community. Manage courts, digital entry passes, and real-time revenue.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Partner Features',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _buildFeatureCard(
            context,
            icon: Icons.qr_code_scanner,
            title: 'Fast Ground QR Pass Check-in',
            subtitle: 'Validate customer bookings at entry in 2 seconds with camera barcode scan.',
            color: Colors.blue,
          ),
          const SizedBox(height: 10),
          _buildFeatureCard(
            context,
            icon: Icons.stadium,
            title: 'Multi-Venue & Court Management',
            subtitle: 'Easily manage box cricket turfs, badminton courts, football fields & tennis arenas.',
            color: Colors.green,
          ),
          const SizedBox(height: 10),
          _buildFeatureCard(
            context,
            icon: Icons.price_change,
            title: 'Dynamic & Peak Pricing Rules',
            subtitle: 'Set custom peak hour surcharges, weekend rates, and automated maintenance slot locks.',
            color: Colors.purple,
          ),
          const SizedBox(height: 10),
          _buildFeatureCard(
            context,
            icon: Icons.account_balance,
            title: 'Automated Payouts & Invoicing',
            subtitle: 'Direct daily settlement into your bank account with transparent commission statements.',
            color: Colors.teal,
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/partner/onboarding'),
              icon: const Icon(Icons.rocket_launch),
              label: const Text('Start Partner Onboarding (3 Min)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerWorkspaceLauncher(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> orgs,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryOrg = orgs.first;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: colorScheme.primary,
                  child: const Icon(Icons.business, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        primaryOrg.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'ACTIVE PARTNER',
                          style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Quick Access', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            leading: const Icon(Icons.dashboard_customize, color: Colors.blue),
            title: const Text('Open Partner Console', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Access real-time bookings, multi-venue manager and revenue'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ref.read(selectedPartnerOrgIdProvider.notifier).state = primaryOrg.id;
              context.push('/partner/workspace');
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            leading: const Icon(Icons.verified_user, color: Colors.green),
            title: const Text('KYC & Verification Status', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('View business credentials and payout bank verification'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => context.push('/partner/kyc-status'),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(selectedPartnerOrgIdProvider.notifier).state = primaryOrg.id;
                context.push('/partner/workspace');
              },
              icon: const Icon(Icons.business_center),
              label: const Text('Enter Partner Operations Workspace', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
