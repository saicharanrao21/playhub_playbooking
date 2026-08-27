import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/security/auth_provider.dart';
import '../../core/models/app_models.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/venues/presentation/screens/venue_details_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/notification_preferences_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/business_dashboard/presentation/screens/business_dashboard_screen.dart';
import '../../features/admin_dashboard/presentation/screens/admin_dashboard_screen.dart';
import '../../features/notifications/presentation/screens/notification_list_screen.dart';
import '../../features/bookings/presentation/screens/booking_list_screen.dart';
import '../../features/bookings/presentation/screens/booking_details_screen.dart';
import '../../features/bookings/presentation/screens/booking_review_screen.dart';
import '../../features/bookings/presentation/screens/reschedule_screen.dart';
import '../../features/availability/presentation/screens/availability_screen.dart';

import '../../features/venues/presentation/screens/venue_media_screen.dart';
import '../../features/venues/presentation/screens/facility_edit_screen.dart';
import '../../features/venues/presentation/screens/venue_edit_screen.dart';
import '../../features/venues/presentation/screens/facility_media_screen.dart';
import '../../features/venues/presentation/screens/facility_create_screen.dart';
import '../../features/venues/presentation/screens/facility_management_screen.dart';
import '../../features/venues/presentation/screens/venue_create_screen.dart';
import '../../features/venues/presentation/screens/venue_management_screen.dart';
import '../../features/business_dashboard/presentation/screens/organization_profile_screen.dart';
import '../../features/admin_dashboard/presentation/screens/activity_management_screen.dart';
import '../../features/admin_dashboard/presentation/screens/city_management_screen.dart';
import '../../features/admin_dashboard/presentation/screens/category_management_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';

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
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login';
      final isAuthenticated = authState.isAuthenticated;

      if (authState.isInitializing) return null;

      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }

      if (isAuthenticated && isLoggingIn) {
        return '/';
      }

      // Role-based route protection
      final user = authState.identity;
      if (user != null) {
        if (state.matchedLocation.startsWith('/admin-dashboard') && 
            user.role != UserRole.admin) {
          return '/';
        }
        
        if (state.matchedLocation.startsWith('/business-dashboard') && 
            user.role != UserRole.businessOwner && 
            user.role != UserRole.admin) {
          return '/';
        }
      }

      return null;
    },
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
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return SearchScreen(initialCategoryId: extra?['categoryId']);
        },
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
        routes: [
          GoRoute(
            path: 'notifications',
            name: 'notification_preferences',
            builder: (context, state) => const NotificationPreferencesScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/bookings',
        name: 'bookings',
        builder: (context, state) => const BookingListScreen(),
      ),
      GoRoute(
        path: '/booking/:id',
        name: 'booking_details',
        builder: (context, state) =>
            BookingDetailsScreen(bookingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/booking/:id/reschedule',
        name: 'booking_reschedule',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return RescheduleScreen(
            bookingId: state.pathParameters['id']!,
            facilityId: extra['facilityId'],
          );
        },
      ),
      GoRoute(
        path: '/availability/:facilityId',
        name: 'availability',
        builder: (context, state) {
          final facilityId = state.pathParameters['facilityId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return AvailabilityScreen(
            facilityId: facilityId,
            facilityName: extra?['facilityName'],
          );
        },
      ),
      GoRoute(
        path: '/booking/review',
        name: 'booking_review',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return BookingReviewScreen(
            facilityId: extra['facilityId'],
            facilityName: extra['facilityName'],
            startTime: DateTime.parse(extra['startTime']),
            endTime: DateTime.parse(extra['endTime']),
          );
        },
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationListScreen(),
      ),
      GoRoute(
        path: '/business-dashboard',
        name: 'business_dashboard',
        builder: (context, state) => const BusinessDashboardScreen(),
        routes: [
          GoRoute(
            path: 'profile',
            name: 'org_profile',
            builder: (context, state) => const OrganizationProfileScreen(),
          ),
          GoRoute(
            path: 'venues',
            name: 'manage_venues',
            builder: (context, state) => const VenueManagementScreen(),
            routes: [
              GoRoute(
                path: 'create',
                name: 'venue_create',
                builder: (context, state) => const VenueCreateScreen(),
              ),
              GoRoute(
                path: ':venueId/edit',
                name: 'venue_edit',
                builder: (context, state) => VenueEditScreen(
                  venueId: state.pathParameters['venueId']!,
                ),
              ),
              GoRoute(
                path: ':venueId/media',
                name: 'venue_media',
                builder: (context, state) => VenueMediaScreen(
                  venueId: state.pathParameters['venueId']!,
                ),
              ),
              GoRoute(
                path: ':venueId/facilities',
                name: 'manage_facilities',
                builder: (context, state) => FacilityManagementScreen(
                  venueId: state.pathParameters['venueId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'create',
                    name: 'facility_create',
                    builder: (context, state) => FacilityCreateScreen(
                      venueId: state.pathParameters['venueId']!,
                    ),
                  ),
                  GoRoute(
                    path: ':facilityId/edit',
                    name: 'facility_edit',
                    builder: (context, state) => FacilityEditScreen(
                      venueId: state.pathParameters['venueId']!,
                      facilityId: state.pathParameters['facilityId']!,
                    ),
                  ),
                  GoRoute(
                    path: ':facilityId/media',
                    name: 'facility_media',
                    builder: (context, state) => FacilityMediaScreen(
                      venueId: state.pathParameters['venueId']!,
                      facilityId: state.pathParameters['facilityId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/admin-dashboard',
        name: 'admin_dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'cities',
            name: 'admin_cities',
            builder: (context, state) => const CityManagementScreen(),
          ),
          GoRoute(
            path: 'categories',
            name: 'admin_categories',
            builder: (context, state) => const CategoryManagementScreen(),
          ),
          GoRoute(
            path: 'activities',
            name: 'admin_activities',
            builder: (context, state) => const ActivityManagementScreen(),
          ),
        ],
      ),
    ],
  );
});
