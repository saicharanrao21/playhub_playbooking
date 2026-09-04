import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/location_provider.dart';
import '../../../../core/models/app_models.dart';
import '../../../home/presentation/providers/discovery_provider.dart';

class SearchQuery {
  final String? query;
  final String? cityId;
  final String? categoryId;
  final String? activityId;
  final double? latitude;
  final double? longitude;
  final double radiusKm;
  final String sortBy;
  final double? minPrice;
  final double? maxPrice;

  SearchQuery({
    this.query,
    this.cityId,
    this.categoryId,
    this.activityId,
    this.latitude,
    this.longitude,
    this.radiusKm = 10.0,
    this.sortBy = 'distance',
    this.minPrice,
    this.maxPrice,
  });

  SearchQuery copyWith({
    String? query,
    String? cityId,
    String? categoryId,
    String? activityId,
    double? latitude,
    double? longitude,
    double? radiusKm,
    String? sortBy,
    double? minPrice,
    double? maxPrice,
    bool clearQuery = false,
    bool clearCategory = false,
    bool clearActivity = false,
  }) {
    return SearchQuery(
      query: clearQuery ? null : (query ?? this.query),
      cityId: cityId ?? this.cityId,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      activityId: clearActivity ? null : (activityId ?? this.activityId),
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusKm: radiusKm ?? this.radiusKm,
      sortBy: sortBy ?? this.sortBy,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
    );
  }
}

final searchStateProvider = StateProvider<SearchQuery>((ref) {
  final location = ref.watch(userLocationProvider);
  final city = ref.watch(selectedCityProvider);

  return SearchQuery(
    latitude: location.latitude,
    longitude: location.longitude,
    radiusKm: location.radiusKm,
    cityId: city?.id,
  );
});

final searchResultsProvider = FutureProvider.autoDispose<List<Venue>>((ref) async {
  final repo = ref.watch(discoveryRepositoryProvider);
  final state = ref.watch(searchStateProvider);
  final location = ref.watch(userLocationProvider);
  final selectedCity = ref.watch(selectedCityProvider);

  final lat = state.latitude ?? location.latitude;
  final lng = state.longitude ?? location.longitude;
  final radius = state.radiusKm;

  return repo.getNearbyVenues(
    latitude: lat,
    longitude: lng,
    radius: radius,
    query: state.query,
    cityId: state.cityId ?? selectedCity?.id,
    categoryId: state.categoryId,
    activityId: state.activityId,
    sortBy: state.sortBy,
  );
});
