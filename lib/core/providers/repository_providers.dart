import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/bootstrap/bootstrap.dart';
import '../security/auth_provider.dart';
import '../repositories/interfaces.dart';
import '../../features/venues/data/venue_repository.dart';
import '../repositories/city_repository.dart';
import '../repositories/category_repository.dart';
import '../repositories/activity_repository.dart';
import '../repositories/discovery_repository.dart';

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
