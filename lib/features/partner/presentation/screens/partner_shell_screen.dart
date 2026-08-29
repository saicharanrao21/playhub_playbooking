import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/security/auth_provider.dart';
import '../providers/partner_providers.dart';

class PartnerShellScreen extends ConsumerStatefulWidget {
  const PartnerShellScreen({super.key});

  @override
  ConsumerState<PartnerShellScreen> createState() => _PartnerShellScreenState();
}

class _PartnerShellScreenState extends ConsumerState<PartnerShellScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentOrg = ref.watch(currentPartnerOrgProvider);
    final orgsAsync = ref.watch(myPartnerOrganizationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Partner Workspace', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('LIVE', style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (currentOrg != null)
              Text(
                currentOrg.name,
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
          ],
        ),
        actions: [
          // Switch organization dropdown if multiple
          orgsAsync.maybeWhen(
            data: (orgs) {
              if (orgs.length <= 1) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                icon: const Icon(Icons.swap_horiz),
                tooltip: 'Switch Organization',
                onSelected: (orgId) {
                  ref.read(selectedPartnerOrgIdProvider.notifier).state = orgId;
                  ref.read(activeOrganizationProvider.notifier).selectOrganization(orgId);
                },
                itemBuilder: (context) => orgs
                    .map((o) => PopupMenuItem(
                          value: o.id,
                          child: Row(
                            children: [
                              Icon(
                                currentOrg != null && o.id == currentOrg.id ? Icons.check_circle : Icons.circle_outlined,
                                size: 16,
                                color: currentOrg != null && o.id == currentOrg.id ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(o.name),
                            ],
                          ),
                        ))
                    .toList(),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(partnerStatsProvider);
              ref.invalidate(partnerVenuesProvider);
              ref.invalidate(partnerBookingsProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Exit to Customer App',
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedTabIndex,
        children: const [
          _PartnerDashboardTab(),
          _PartnerBookingsTab(),
          _PartnerVenuesTab(),
          _PartnerBusinessTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (idx) => setState(() => _selectedTabIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.stadium_outlined),
            selectedIcon: Icon(Icons.stadium),
            label: 'Venues',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business),
            label: 'Business & KYC',
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 1: DASHBOARD
// -------------------------------------------------------------
class _PartnerDashboardTab extends ConsumerWidget {
  const _PartnerDashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final statsAsync = ref.watch(partnerStatsProvider);
    final venuesAsync = ref.watch(partnerVenuesProvider);
    final bookingsAsync = ref.watch(partnerBookingsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(partnerStatsProvider);
        ref.invalidate(partnerVenuesProvider);
        ref.invalidate(partnerBookingsProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KYC Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Partner Status: Active & Verified', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Direct bank settlement active for your sports facilities.', style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/partner/kyc-status'),
                    child: const Text('View KYC', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Text('Operational Metrics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            statsAsync.when(
              data: (stats) => Column(
                children: [
                  Row(
                    children: [
                      _buildMetricTile(context, 'Today Bookings', '${stats?.todayBookings ?? 0}', Icons.today, Colors.blue),
                      const SizedBox(width: 12),
                      _buildMetricTile(context, 'Upcoming Slots', '${stats?.upcomingBookings ?? 0}', Icons.calendar_month, Colors.green),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMetricTile(context, 'Active Venues', '${stats?.venuesCount ?? 0}', Icons.business, Colors.orange),
                      const SizedBox(width: 12),
                      _buildMetricTile(context, 'Total Courts', '${stats?.facilitiesCount ?? 0}', Icons.sports_soccer, Colors.purple),
                    ],
                  ),
                ],
              ),
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator())),
              error: (err, stack) => Text('Error loading stats: $err'),
            ),

            const SizedBox(height: 24),
            const Text('Quick Operational Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildActionBtn(
                    context,
                    icon: Icons.add_business,
                    label: 'Add Venue',
                    color: colorScheme.primary,
                    onTap: () => context.push('/partner/venues/create'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionBtn(
                    context,
                    icon: Icons.qr_code_scanner,
                    label: 'Check-in Pass',
                    color: Colors.teal,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('📷 Fast QR Scanner ready for camera entry.')),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent Bookings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                venuesAsync.maybeWhen(
                  data: (venues) => Text('${venues.length} Managed Venues', style: TextStyle(fontSize: 12, color: colorScheme.primary)),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            bookingsAsync.when(
              data: (bookings) {
                if (bookings.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.event_available, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        const Text('No bookings scheduled for today.', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('New customer slots will appear here in real-time.', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bookings.length > 3 ? 3 : bookings.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, idx) {
                    final b = bookings[idx];
                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(Icons.sports_soccer, color: colorScheme.primary, size: 20),
                        ),
                        title: Text('${b.facilityName} (${b.venueName})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text('${b.customerName} • ${_formatTime(b.startTime)}', style: const TextStyle(fontSize: 11)),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('₹${b.totalPrice.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const Text('Could not load recent bookings.'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(BuildContext context, String title, String value, IconData icon, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $ampm';
  }
}

// -------------------------------------------------------------
// TAB 2: BOOKINGS
// -------------------------------------------------------------
class _PartnerBookingsTab extends ConsumerWidget {
  const _PartnerBookingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(partnerBookingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(partnerBookingsProvider.future),
      child: bookingsAsync.when(
        data: (bookings) {
          if (bookings.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('No Active Bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Customer slots will appear here as soon as they are booked on PlayHub.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final booking = bookings[idx];
              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            booking.facilityName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              booking.status,
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(booking.venueName, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                      const Divider(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(booking.customerName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                          const Spacer(),
                          const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(booking.customerPhone, style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            '${_formatDateTime(booking.startTime)} - ${_formatDateTime(booking.endTime)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          const Spacer(),
                          Text(
                            '₹${booking.totalPrice.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading bookings: $err')),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute $ampm';
  }
}

// -------------------------------------------------------------
// TAB 3: VENUES & FACILITIES
// -------------------------------------------------------------
class _PartnerVenuesTab extends ConsumerWidget {
  const _PartnerVenuesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venuesAsync = ref.watch(partnerVenuesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/partner/venues/create'),
        icon: const Icon(Icons.add),
        label: const Text('Add Venue'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(partnerVenuesProvider.future),
        child: venuesAsync.when(
          data: (venues) {
            if (venues.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.stadium_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text('No Venues Created Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first sports turf, box cricket arena, or badminton academy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/partner/venues/create'),
                        icon: const Icon(Icons.add),
                        label: const Text('Create New Venue'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: venues.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final venue = venues[idx];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: colorScheme.primaryContainer,
                              child: Icon(Icons.sports, color: colorScheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(venue.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('${venue.city}, ${venue.state}', style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(venue.status, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 10)),
                            ),
                          ],
                        ),
                        if (venue.description != null && venue.description!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(venue.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                        ],
                        const Divider(height: 24),
                        Row(
                          children: [
                            Icon(Icons.layers_outlined, size: 16, color: colorScheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              '${venue.facilities.length} Courts / Pitches',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: colorScheme.primary),
                            ),
                            const Spacer(),
                            OutlinedButton.icon(
                              onPressed: () => context.push('/partner/venues/${venue.id}'),
                              icon: const Icon(Icons.settings, size: 14),
                              label: const Text('Manage Courts', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// TAB 4: BUSINESS PROFILE & KYC
// -------------------------------------------------------------
class _PartnerBusinessTab extends ConsumerWidget {
  const _PartnerBusinessTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentOrg = ref.watch(currentPartnerOrgProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: colorScheme.primary,
                    child: const Icon(Icons.business_center, color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentOrg?.name ?? 'Sports Organization',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('ORGANIZATION ACTIVE', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Text('Verification & Compliance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.verified_user, color: Colors.green),
                  title: const Text('KYC Document Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('PAN, GSTIN & Business Registration'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.push('/partner/kyc-status'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.account_balance, color: Colors.blue),
                  title: const Text('Settlement Bank Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: const Text('Direct automated booking payouts'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => context.push('/partner/kyc-status'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Text('Role & Access', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),

          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: ListTile(
              leading: const Icon(Icons.badge, color: Colors.purple),
              title: const Text('Assigned Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(currentOrg?.roles.join(', ') ?? 'PARTNER_OWNER'),
              trailing: const Chip(label: Text('Full Access', style: TextStyle(fontSize: 10))),
            ),
          ),

          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Switch to Player / Customer Mode'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
