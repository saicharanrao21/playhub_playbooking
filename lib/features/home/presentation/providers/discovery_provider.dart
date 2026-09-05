import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/location_provider.dart';
import '../../../../core/models/app_models.dart';
import '../../../../app/bootstrap/bootstrap.dart';

final citiesProvider = FutureProvider<List<City>>((ref) async {
  final repo = ref.watch(cityRepositoryProvider);
  return repo.getCities();
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.getCategories();
});

final selectedCityProvider = StateProvider<City?>((ref) => null);

final discoverVenuesProvider = FutureProvider<List<Venue>>((ref) async {
  final repo = ref.watch(discoveryRepositoryProvider);
  final selectedCity = ref.watch(selectedCityProvider);
  
  return repo.discoverVenues(
    cityId: selectedCity?.id,
  );
});

final nearbyVenuesProvider = FutureProvider.autoDispose<List<Venue>>((ref) async {
  final repo = ref.watch(discoveryRepositoryProvider);
  final location = ref.watch(userLocationProvider);
  final selectedCity = ref.watch(selectedCityProvider);

  return repo.getNearbyVenues(
    latitude: location.latitude,
    longitude: location.longitude,
    radius: location.radiusKm,
    cityId: selectedCity?.id,
  );
});

final recommendationsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final location = ref.watch(userLocationProvider);
  final response = await apiClient.get<List<dynamic>>(
    '/recommendations',
    queryParameters: {
      'latitude': location.latitude.toString(),
      'longitude': location.longitude.toString(),
      'radius': location.radiusKm.toString(),
    },
  );
  return response.isSuccess ? (response.data ?? []) : [];
});
