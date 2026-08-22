import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/models/app_models.dart';

class SearchQuery {
  final String? query;
  final String? cityId;
  final String? categoryId;
  final String? activityId;

  SearchQuery({this.query, this.cityId, this.categoryId, this.activityId});

  SearchQuery copyWith({
    String? query,
    String? cityId,
    String? categoryId,
    String? activityId,
  }) {
    return SearchQuery(
      query: query ?? this.query,
      cityId: cityId ?? this.cityId,
      categoryId: categoryId ?? this.categoryId,
      activityId: activityId ?? this.activityId,
    );
  }
}

final searchStateProvider = StateProvider<SearchQuery>((ref) => SearchQuery());

final searchResultsProvider = FutureProvider<List<Venue>>((ref) async {
  final repo = ref.watch(discoveryRepositoryProvider);
  final state = ref.watch(searchStateProvider);
  
  return repo.discoverVenues(
    query: state.query,
    cityId: state.cityId,
    categoryId: state.categoryId,
    activityId: state.activityId,
  );
});
