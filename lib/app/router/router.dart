import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/venues/presentation/screens/venue_details_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/business_dashboard/presentation/screens/business_dashboard_screen.dart';
import '../../features/admin_dashboard/presentation/screens/admin_dashboard_screen.dart';

// Placeholder for screens not yet implemented in detail
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(child: Text('Welcome to $title')),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  // Future: Watch auth state to perform redirects
  // final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Search Results'),
      ),
      GoRoute(
        path: '/venue/:id',
        name: 'venue_details',
        builder: (context, state) =>
            VenueDetailsScreen(venueId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/booking',
        name: 'booking',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Booking Confirmation'),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/business-dashboard',
        name: 'business_dashboard',
        builder: (context, state) => const BusinessDashboardScreen(),
      ),
      GoRoute(
        path: '/admin-dashboard',
        name: 'admin_dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
    // Future: implement redirect logic based on auth state
    // redirect: (context, state) { ... }
  );
});
