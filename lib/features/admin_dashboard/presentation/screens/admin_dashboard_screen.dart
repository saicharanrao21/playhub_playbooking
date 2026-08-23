import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_provider.dart';
import '../../../../core/providers/repository_providers.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _approveBusiness(BuildContext context, WidgetRef ref, String id) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final repo = ref.read(adminRepositoryProvider);
    final success = await repo.approveBusiness(id);
    
    if (success) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Business approved!')));
      ref.invalidate(adminStatsProvider);
    } else {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Failed to approve business.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: statsAsync.when(
        data: (stats) => Row(
          children: [
            // Sidebar (Visible on Desktop/Tablet)
            if (MediaQuery.of(context).size.width > 800)
              NavigationRail(
                extended: true,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard),
                    label: Text('Dashboard'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.location_city),
                    label: Text('Cities'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.category),
                    label: Text('Categories'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.directions_run),
                    label: Text('Activities'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.business),
                    label: Text('Organizations'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.settings),
                    label: Text('Settings'),
                  ),
                ],
                selectedIndex: 0,
                onDestinationSelected: (int index) {
                  if (index == 1) context.push('/admin-dashboard/cities');
                  if (index == 2) context.push('/admin-dashboard/categories');
                  if (index == 3) context.push('/admin-dashboard/activities');
                },
              ),

            // Main Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.refresh(adminStatsProvider.future),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Platform Overview',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: MediaQuery.of(context).size.width > 1200
                            ? 4
                            : (MediaQuery.of(context).size.width > 600 ? 2 : 1),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          _buildAdminStatCard(
                            'Total Users',
                            '${stats?.totalUsers ?? 0}',
                            Icons.people,
                            Colors.blue,
                          ),
                          _buildAdminStatCard(
                            'Active Venues',
                            '${stats?.totalVenues ?? 0}',
                            Icons.business,
                            Colors.green,
                          ),
                          _buildAdminStatCard(
                            'Active Bookings',
                            '${stats?.activeBookings ?? 0}',
                            Icons.book,
                            Colors.orange,
                          ),
                          _buildAdminStatCard(
                            'Pending Approvals',
                            '${stats?.pendingBusinesses.length ?? 0}',
                            Icons.approval,
                            Colors.purple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Recent Organization Requests',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (stats != null && stats.pendingBusinesses.isNotEmpty)
                        Card(
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: stats.pendingBusinesses.length,
                            separatorBuilder: (context, index) => const Divider(),
                            itemBuilder: (context, index) {
                              final biz = stats.pendingBusinesses[index];
                              return ListTile(
                                title: Text(biz['displayName'] ?? 'Unknown Business'),
                                subtitle: Text('Organization: ${biz['organization']?['name'] ?? 'N/A'}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      onPressed: () {},
                                      child: const Text(
                                        'Reject',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _approveBusiness(context, ref, biz['id']),
                                      child: const Text('Approve'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      else
                        const Center(child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text('No pending business requests.'),
                        )),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading dashboard: $err')),
      ),
    );
  }

  Widget _buildAdminStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
