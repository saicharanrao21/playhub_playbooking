import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/dummy_repositories.dart';
import '../repositories/interfaces.dart';

final venueRepositoryProvider = Provider<IVenueRepository>((ref) {
  return DummyVenueRepository();
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
