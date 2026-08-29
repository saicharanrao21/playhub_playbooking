import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/security/auth_provider.dart';
import '../../core/models/app_models.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/home/presentation/screens/match_discovery_screen.dart';
import '../../features/home/presentation/screens/host_match_screen.dart';
import '../../features/home/presentation/screens/community_feed_screen.dart';
import '../../features/venues/presentation/screens/venue_details_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/wallet_screen.dart';
import '../../features/profile/presentation/screens/notification_preferences_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
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
import '../../features/search/presentation/screens/search_screen.dart';
import '../../features/tournaments/presentation/screens/tournaments_screen.dart';
import '../../features/tournaments/presentation/screens/tournament_details_screen.dart';
import '../../features/home/presentation/screens/match_details_screen.dart';
import '../../features/profile/presentation/screens/account_security_screen.dart';
import '../../features/profile/presentation/screens/help_support_screen.dart';
import '../../features/admin_dashboard/presentation/screens/city_management_screen.dart';
import '../../features/admin_dashboard/presentation/screens/category_management_screen.dart';
import '../../features/admin_dashboard/presentation/screens/activity_management_screen.dart';
import '../../features/admin_dashboard/presentation/screens/user_management_screen.dart';
import '../../features/partner/presentation/screens/partner_entry_screen.dart';
import '../../features/partner/presentation/screens/partner_onboarding_screen.dart';
import '../../features/partner/presentation/screens/partner_shell_screen.dart';
import '../../features/partner/presentation/screens/partner_venue_create_screen.dart';
import '../../features/partner/presentation/screens/partner_venue_details_screen.dart';
import '../../features/partner/presentation/screens/partner_facility_create_screen.dart';
import '../../features/partner/presentation/screens/partner_kyc_status_screen.dart';
import '../../features/partner/presentation/screens/partner_pricing_rules_screen.dart';
import '../../features/partner/presentation/screens/partner_pricing_rule_create_screen.dart';
import '../../features/partner/presentation/screens/partner_booking_details_screen.dart';
import '../../features/partner/presentation/screens/partner_qr_scanner_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isAuthFlow = loc == '/login' || loc == '/signup' || loc == '/forgot-password' || loc == '/email-verification';
      final isAuthenticated = authState.isAuthenticated;

      if (authState.isInitializing) return null;

      if (!isAuthenticated && !isAuthFlow) {
        return '/login';
      }

      if (isAuthenticated && isAuthFlow) {
        return '/';
      }

      // Role-based route protection
      final user = authState.identity;
      if (user != null) {
        if (loc.startsWith('/admin-dashboard') && user.role != UserRole.admin) {
          return '/';
        }
        
        if (loc.startsWith('/business-dashboard') && 
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
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot_password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/email-verification',
        name: 'email_verification',
        builder: (context, state) => const EmailVerificationScreen(),
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
        path: '/find-matches',
        name: 'find_matches',
        builder: (context, state) => const MatchDiscoveryScreen(),
      ),
      GoRoute(
        path: '/host-match',
        name: 'host_match',
        builder: (context, state) => const HostMatchScreen(),
      ),
      GoRoute(
        path: '/community-feed',
        name: 'community_feed',
        builder: (context, state) => const CommunityFeedScreen(),
      ),
      GoRoute(
        path: '/wallet',
        name: 'wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/venue/:id',
        name: 'venue_details',
        builder: (context, state) =>
            VenueDetailsScreen(venueId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/tournaments',
        name: 'tournaments',
        builder: (context, state) => const TournamentsScreen(),
      ),
      GoRoute(
        path: '/tournament/:id',
        name: 'tournament_details',
        builder: (context, state) =>
            TournamentDetailsScreen(tournamentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/match/:id',
        name: 'match_details',
        builder: (context, state) => MatchDetailsScreen(
          matchId: state.pathParameters['id']!,
          match: state.extra as MatchItem?,
        ),
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
          GoRoute(
            path: 'security',
            name: 'account_security',
            builder: (context, state) => const AccountSecurityScreen(),
          ),
          GoRoute(
            path: 'help',
            name: 'help_support',
            builder: (context, state) => const HelpSupportScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/bookings',
        name: 'bookings',
        builder: (context, state) => const BookingListScreen(),
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
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationListScreen(),
      ),
      GoRoute(
        path: '/business/venues/create',
        name: 'business_venue_create_alias',
        builder: (context, state) => const VenueCreateScreen(),
      ),
      GoRoute(
        path: '/business/venues/edit/:venueId',
        name: 'business_venue_edit_alias',
        builder: (context, state) => VenueEditScreen(
          venueId: state.pathParameters['venueId']!,
        ),
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
          GoRoute(
            path: 'users',
            name: 'admin_users',
            builder: (context, state) => const UserManagementScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/partner',
        name: 'partner_entry',
        builder: (context, state) => const PartnerEntryScreen(),
        routes: [
          GoRoute(
            path: 'onboarding',
            name: 'partner_onboarding',
            builder: (context, state) => const PartnerOnboardingScreen(),
          ),
          GoRoute(
            path: 'workspace',
            name: 'partner_workspace',
            builder: (context, state) => const PartnerShellScreen(),
          ),
          GoRoute(
            path: 'kyc-status',
            name: 'partner_kyc_status',
            builder: (context, state) => const PartnerKYCStatusScreen(),
          ),
          GoRoute(
            path: 'venues/create',
            name: 'partner_venue_create',
            builder: (context, state) => const PartnerVenueCreateScreen(),
          ),
          GoRoute(
            path: 'venues/:venueId',
            name: 'partner_venue_details',
            builder: (context, state) => PartnerVenueDetailsScreen(
              venueId: state.pathParameters['venueId']!,
            ),
            routes: [
              GoRoute(
                path: 'facilities/create',
                name: 'partner_facility_create',
                builder: (context, state) => PartnerFacilityCreateScreen(
                  venueId: state.pathParameters['venueId']!,
                ),
              ),
              GoRoute(
                path: 'bookings/scanner',
                name: 'partner_booking_scanner',
                builder: (context, state) => const PartnerQrScannerScreen(),
              ),
              GoRoute(
                path: 'bookings/:bookingId',
                name: 'partner_booking_details',
                builder: (context, state) => PartnerBookingDetailsScreen(
                  bookingId: state.pathParameters['bookingId']!,
                ),
              ),
              GoRoute(
                path: 'facilities/:facilityId/pricing',
                name: 'partner_pricing_rules',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  return PartnerPricingRulesScreen(
                    venueId: state.pathParameters['venueId']!,
                    facilityId: state.pathParameters['facilityId']!,
                    facilityName: extra['facilityName'] ?? 'Facility',
                  );
                },
                routes: [
                  GoRoute(
                    path: 'create',
                    name: 'partner_pricing_rule_create',
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>;
                      return PartnerPricingRuleCreateScreen(
                        facilityId: state.pathParameters['facilityId']!,
                        facilityName: extra['facilityName'] ?? 'Facility',
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

