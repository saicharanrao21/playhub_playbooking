import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:playhub_playbooking/features/admin_dashboard/presentation/providers/admin_provider.dart';
import 'package:playhub_playbooking/shared/components/error_view.dart';
import 'package:playhub_playbooking/shared/components/loading_indicator.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Console', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(adminStatsProvider.future),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => RefreshIndicator(
          onRefresh: () => ref.refresh(adminStatsProvider.future),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Platform Overview Header
                Text(
                  'Platform Telemetry & Metrics',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _buildAdminStatCard(
                      context,
                      'Total Users',
                      '${stats?.totalUsers ?? 0}',
                      Icons.people_alt_outlined,
                      Colors.blue,
                      onTap: () => context.push('/admin-dashboard/users'),
                    ),
                    _buildAdminStatCard(
                      context,
                      'Venues',
                      '${stats?.totalVenues ?? 0}',
                      Icons.business_outlined,
                      Colors.green,
                    ),
                    _buildAdminStatCard(
                      context,
                      'Active Bookings',
                      '${stats?.activeBookings ?? 0}',
                      Icons.confirmation_number_outlined,
                      Colors.orange,
                    ),
                    _buildAdminStatCard(
                      context,
                      'Pending Reviews',
                      '${stats?.pendingKYC ?? 0}',
                      Icons.verified_user_outlined,
                      Colors.purple,
                      onTap: () => context.push('/admin-dashboard/partners?status=SUBMITTED'),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Platform Governance & Configuration
                Text(
                  'System Configuration',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(Icons.location_city, color: colorScheme.primary),
                        ),
                        title: const Text('Manage Cities', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Add, edit, or configure active operating cities'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/admin-dashboard/cities'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(Icons.category, color: colorScheme.primary),
                        ),
                        title: const Text('Manage Categories', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Configure sport types and venue categories'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/admin-dashboard/categories'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(Icons.directions_run, color: colorScheme.primary),
                        ),
                        title: const Text('Manage Activities', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Create game formats and sports activity tags'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/admin-dashboard/activities'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(Icons.people_outline, color: colorScheme.primary),
                        ),
                        title: const Text('User Management & RBAC', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('View registered users, roles, and status'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/admin-dashboard/users'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(Icons.history, color: colorScheme.primary),
                        ),
                        title: const Text('Platform Audit Trail', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Track all administrative and security actions'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/admin-dashboard/audit'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(Icons.assignment_ind_outlined, color: colorScheme.primary),
                        ),
                        title: const Text('Partner Applications', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Review and approve new sports venue partners'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/admin-dashboard/partners'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Organization Approvals
                Text(
                  'Pending Action Items',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.purple,
                          child: Icon(Icons.verified_user, color: Colors.white, size: 20),
                        ),
                        title: const Text('Partner Applications', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${stats?.pendingKYC ?? 0} applications awaiting KYC review'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/admin-dashboard/partners?status=SUBMITTED'),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.business, color: Colors.white, size: 20),
                        ),
                        title: const Text('New Businesses', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${stats?.pendingBusinesses ?? 0} businesses pending onboarding'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/admin-dashboard/partners'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            SkeletonCard(height: 140),
            SizedBox(height: 16),
            SkeletonCard(height: 200),
          ],
        ),
        error: (err, _) => AppErrorView(
          message: 'Error loading admin dashboard: $err',
          onRetry: () => ref.refresh(adminStatsProvider.future),
        ),
      ),
    );
  }

  Widget _buildAdminStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                title,
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
