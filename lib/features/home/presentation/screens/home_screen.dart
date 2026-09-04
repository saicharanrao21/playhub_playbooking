import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:playhub_playbooking/core/providers/location_provider.dart';
import 'package:playhub_playbooking/features/home/presentation/providers/discovery_provider.dart';
import 'package:playhub_playbooking/shared/components/empty_view.dart';
import 'package:playhub_playbooking/shared/components/error_view.dart';
import 'package:playhub_playbooking/shared/components/location_picker_modal.dart';
import 'package:playhub_playbooking/features/home/presentation/screens/match_discovery_screen.dart';
import 'package:playhub_playbooking/features/home/presentation/screens/community_feed_screen.dart';
import 'package:playhub_playbooking/features/profile/presentation/screens/profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    _HomeContent(),
    MatchDiscoveryScreen(),
    CommunityFeedScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isTabletOrDesktop = MediaQuery.of(context).size.width > 700;

    if (isTabletOrDesktop) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              extended: MediaQuery.of(context).size.width > 1000,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.sports_soccer_outlined),
                  selectedIcon: Icon(Icons.sports_soccer),
                  label: Text('Matches'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups),
                  label: Text('Social'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: Text('Profile'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: _screens[_selectedIndex]),
          ],
        ),
      );
    }

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_soccer_outlined),
            selectedIcon: Icon(Icons.sports_soccer),
            label: 'Matches',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Social',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent();

  void _showLocationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const LocationPickerModal(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final location = ref.watch(userLocationProvider);
    final nearbyVenuesAsync = ref.watch(nearbyVenuesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PlayHub',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            GestureDetector(
              onTap: () => _showLocationPicker(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    location.isGps ? Icons.my_location : Icons.location_on,
                    size: 13,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${location.locationName} • ${location.radiusKm.toInt()} km',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Map View',
            onPressed: () => context.push('/map'),
          ),
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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(nearbyVenuesProvider);
          ref.invalidate(categoriesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar + Map Button Row
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search venues, sports, areas...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      ),
                      onTap: () => context.push('/search'),
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () => context.push('/map'),
                    icon: const Icon(Icons.map),
                    tooltip: 'Map Discovery',
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _QuickAction(
                    icon: Icons.add_circle_outline,
                    label: 'Host Match',
                    onTap: () => context.push('/host-match'),
                  ),
                  _QuickAction(
                    icon: Icons.sports_soccer_outlined,
                    label: 'Find Match',
                    onTap: () => context.push('/find-matches'),
                  ),
                  _QuickAction(
                    icon: Icons.emoji_events_outlined,
                    label: 'Tournaments',
                    onTap: () => context.push('/tournaments'),
                  ),
                  _QuickAction(
                    icon: Icons.near_me_outlined,
                    label: 'Near Me',
                    onTap: () => context.push('/map'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Categories Header
              Text(
                'Explore Sports & Categories',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              categoriesAsync.when(
                data: (categories) => SizedBox(
                  height: 96,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    separatorBuilder: (c, i) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      return InkWell(
                        onTap: () => context.push('/search', extra: {'categoryId': cat.id}),
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getCategoryIcon(cat.slug),
                                color: colorScheme.onPrimaryContainer,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              cat.name,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                loading: () => const SizedBox(height: 96, child: Center(child: CircularProgressIndicator())),
                error: (err, stack) => Text('Error: $err'),
              ),

              const SizedBox(height: 24),

              // Nearby Venues Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nearby Venues (${location.radiusKm.toInt()} km)',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/map'),
                    icon: const Icon(Icons.map, size: 16),
                    label: const Text('Map View'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              nearbyVenuesAsync.when(
                data: (venues) {
                  if (venues.isEmpty) {
                    return EmptyView(
                      icon: Icons.stadium_outlined,
                      title: 'No venues within ${location.radiusKm.toInt()} km',
                      message: 'Try increasing your search radius or changing your location.',
                      actionLabel: 'Adjust Radius',
                      onAction: () => _showLocationPicker(context),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: venues.length,
                    itemBuilder: (context, index) {
                      final venue = venues[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 1.5,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => context.push('/venue/${venue.id}'),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Venue Image / Placeholder
                              Stack(
                                children: [
                                  Container(
                                    height: 140,
                                    width: double.infinity,
                                    color: colorScheme.surfaceContainerHighest,
                                    child: venue.imageUrls.isNotEmpty
                                        ? Image.network(venue.imageUrls.first, fit: BoxFit.cover)
                                        : Icon(Icons.stadium, size: 64, color: colorScheme.outlineVariant),
                                  ),
                                  if (venue.distanceFormatted != null)
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.navigation, color: Colors.white, size: 12),
                                            const SizedBox(width: 4),
                                            Text(
                                              venue.distanceFormatted!,
                                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            venue.name,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.star, size: 16, color: Colors.amber),
                                            const SizedBox(width: 2),
                                            Text(
                                              venue.rating.toStringAsFixed(1),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${venue.address}, ${venue.city}',
                                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                error: (err, stack) => AppErrorView(
                  message: 'Error loading nearby venues: $err',
                  onRetry: () => ref.refresh(nearbyVenuesProvider.future),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String slug) {
    switch (slug) {
      case 'sports':
      case 'football':
        return Icons.sports_soccer;
      case 'cricket':
        return Icons.sports_cricket;
      case 'badminton':
        return Icons.sports_tennis;
      case 'swimming':
        return Icons.pool;
      default:
        return Icons.sports;
    }
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colorScheme.primary, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
