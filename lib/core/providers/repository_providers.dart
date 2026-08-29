export '../repositories/match_repository.dart';
export '../repositories/community_repository.dart';
export '../repositories/wallet_repository.dart';
export '../../features/tournaments/data/tournament_repository.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/bootstrap/bootstrap.dart';
import '../security/auth_provider.dart';
import '../repositories/interfaces.dart';
import '../../features/venues/data/venue_repository.dart';
import '../../features/venues/data/venue_operator_repository.dart';
import '../repositories/city_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/activity_repository.dart';
import '../repositories/discovery_repository.dart';
import '../repositories/media_repository.dart';
import '../repositories/communication_repository.dart';
import '../../features/business_dashboard/data/dashboard_repository.dart';
import '../../features/admin_dashboard/data/admin_repository.dart';

final venueRepositoryProvider = Provider<IVenueRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final orgId = ref.watch(activeOrganizationProvider) ?? '';
  return VenueRepository(apiClient, orgId);
});

final categoryRepositoryProvider = Provider<ICategoryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CategoryRepository(apiClient);
});

final cityRepositoryProvider = Provider<ICityRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CityRepository(apiClient);
});

final activityRepositoryProvider = Provider<IActivityRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ActivityRepository(apiClient);
});

final discoveryRepositoryProvider = Provider<IDiscoveryRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DiscoveryRepository(apiClient);
});

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final orgId = ref.watch(activeOrganizationProvider) ?? '';
  return MediaRepository(apiClient, orgId);
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardRepository(apiClient);
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AdminRepository(apiClient);
});

final venueOperatorRepositoryProvider = Provider<VenueOperatorRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final orgId = ref.watch(activeOrganizationProvider) ?? '';
  return VenueOperatorRepository(apiClient, orgId);
});

final communicationRepositoryProvider = Provider<CommunicationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CommunicationRepository(apiClient);
});
