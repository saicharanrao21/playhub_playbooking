import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/models/app_models.dart';

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
