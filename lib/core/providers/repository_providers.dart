import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/bootstrap/bootstrap.dart';
import '../security/auth_provider.dart';
import '../repositories/interfaces.dart';
import '../repositories/dummy_repositories.dart';
import '../../features/venues/data/venue_repository.dart';

final venueRepositoryProvider = Provider<IVenueRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final authState = ref.watch(authStateProvider);
  final orgId = authState.identity?.organizationId ?? '';
  return VenueRepository(apiClient, orgId);
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return DummyAuthRepository();
});

final categoryRepositoryProvider = Provider<ICategoryRepository>((ref) {
  return DummyCategoryRepository();
});

final cityRepositoryProvider = Provider<ICityRepository>((ref) {
  return DummyCityRepository();
});
