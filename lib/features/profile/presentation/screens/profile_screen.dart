import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:playhub_playbooking/core/security/auth_provider.dart';
import 'package:playhub_playbooking/core/models/app_models.dart';
import 'package:playhub_playbooking/shared/components/loading_indicator.dart';
import 'wallet_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authStateProvider);
    final user = authState.identity;
    final walletAsync = ref.watch(walletInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            tooltip: 'Wallet',
            onPressed: () => context.push('/wallet'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // User Avatar & Info Card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Text(
                          (user != null && user.name.isNotEmpty) ? user.name[0].toUpperCase() : 'P',
                          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: colorScheme.primary,
                          child: Icon(Icons.camera_alt, size: 14, color: colorScheme.onPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'Player One',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'player@playhub.com',
                    style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  if (user != null)
                    Chip(
                      label: Text(
                        user.role.name.toUpperCase(),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: colorScheme.secondaryContainer.withValues(alpha: 0.6),
                      side: BorderSide.none,
                      visualDensity: VisualDensity.compact,
                    ),
                  const SizedBox(height: 20),

                  // Stats Row
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStat(context, 'Matches', '42'),
                        _buildStatDivider(context),
                        _buildStat(context, 'Rating', '4.9 ★'),
                        _buildStatDivider(context),
                        _buildStat(context, 'Reliability', '98%'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Quick Wallet Banner
          walletAsync.when(
            data: (wallet) => Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(Icons.account_balance_wallet, color: colorScheme.primary),
                ),
                title: const Text('PlayHub Wallet', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Balance: ₹${wallet.balance.toStringAsFixed(2)}'),
                trailing: ElevatedButton(
                  onPressed: () => context.push('/wallet'),
                  style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: const Text('Top Up'),
                ),
                onTap: () => context.push('/wallet'),
              ),
            ),
            loading: () => const SkeletonCard(height: 65),
            error: (err, stack) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 16),

          // Section 1: Bookings & Activity
          _buildSectionHeader(context, 'My Activity'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildMenuItem(
                  context,
                  Icons.calendar_month_outlined,
                  'My Bookings',
                  'View confirmed, pending, and past bookings',
                  () => context.push('/bookings'),
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  context,
                  Icons.sports_soccer_outlined,
                  'My Matches & Hosted Games',
                  'Find open games and manage your hosted matches',
                  () => context.push('/find-matches'),
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  context,
                  Icons.group_outlined,
                  'My Communities',
                  'Connect with local sports groups & discussions',
                  () => context.push('/community-feed'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section 2: Rewards, Offers & Memberships
          _buildSectionHeader(context, 'Rewards, Offers & Memberships'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildMenuItem(
                  context,
                  Icons.card_membership_outlined,
                  'PlayHub Memberships',
                  'View active membership, plan perks & benefits',
                  () => context.push('/profile/memberships'),
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  context,
                  Icons.local_offer_outlined,
                  'Offers & Promo Coupons',
                  'Claim court discounts & view available promo codes',
                  () => context.push('/profile/coupons'),
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  context,
                  Icons.card_giftcard_outlined,
                  'Refer & Earn',
                  'Invite friends and earn ₹100 in PlayHub loyalty points',
                  () => context.push('/profile/referral'),
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  context,
                  Icons.stars_outlined,
                  'Loyalty Points Ledger',
                  'View earned points balance and redemption history',
                  () => context.push('/profile/loyalty'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section 3: Partner & Venue Management
          _buildSectionHeader(context, 'Partner & Management'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildMenuItem(
                  context,
                  Icons.business_center_outlined,
                  'Partner & Venue Hub',
                  'Register sports business, manage courts & live bookings',
                  () => context.push('/partner'),
                ),
                if (ref.hasRole(UserRole.admin)) ...[
                  const Divider(height: 1),
                  _buildMenuItem(
                    context,
                    Icons.admin_panel_settings_outlined,
                    'Admin Dashboard',
                    'Platform statistics, approvals, and RBAC control',
                    () => context.push('/admin-dashboard'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 3: Preferences & Settings
          _buildSectionHeader(context, 'Settings & Preferences'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _buildMenuItem(
                  context,
                  Icons.notifications_active_outlined,
                  'Notification Preferences',
                  'Manage push, email, SMS, and WhatsApp alerts',
                  () => context.push('/profile/notifications'),
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  context,
                  Icons.security_outlined,
                  'Account Security',
                  'Password management & login sessions',
                  () => context.push('/profile/security'),
                ),
                const Divider(height: 1),
                _buildMenuItem(
                  context,
                  Icons.help_outline,
                  'Help & Support',
                  'FAQs, live chat, and support tickets',
                  () => context.push('/profile/help'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Logout Action
          OutlinedButton.icon(
            onPressed: () {
              _showLogoutDialog(context, ref);
            },
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Logout from PlayHub', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildStat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatDivider(BuildContext context) {
    return Container(
      height: 28,
      width: 1,
      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap, {
    Color? color,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: color ?? colorScheme.primary),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out of your PlayHub account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authStateProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
