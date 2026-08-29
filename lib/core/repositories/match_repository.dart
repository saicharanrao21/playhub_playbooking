import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:playhub_playbooking/app/bootstrap/bootstrap.dart';
import 'package:playhub_playbooking/core/networking/api_client_interface.dart';
import '../models/app_models.dart';

abstract class MatchRepository {
  Future<List<MatchItem>> getMatches({String? sport, String? search});
  Future<MatchItem?> getMatchById(String matchId);
  Future<bool> joinMatch(String matchId);
  Future<bool> hostMatch({
    required String title,
    required String sport,
    required int maxPlayers,
    required DateTime startTime,
    required DateTime endTime,
    required double pricePerPlayer,
    required String venueName,
    required String location,
    String? description,
    String? skillLevel,
  });
}

class MatchRepositoryImpl implements MatchRepository {
  final IApiClient apiClient;

  MatchRepositoryImpl({required this.apiClient});

  // Local simulated store initialized with seed matches
  final List<MatchItem> _matches = [
    MatchItem(
      id: 'match_001',
      hostId: 'usr_001',
      venueName: 'Skyline Sports Arena, Madhapur',
      location: 'Madhapur, Hyderabad',
      sport: 'Cricket',
      title: 'Friendly Weekend T20 Match',
      description: 'Looking for 5 enthusiastic players for a friendly 20-over match. Leather ball provided.',
      startTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
      endTime: DateTime.now().add(const Duration(days: 1, hours: 5)),
      maxPlayers: 11,
      currentPlayers: 7,
      skillLevelRequired: 'Intermediate',
      pricePerPlayer: 250.0,
      status: MatchStatus.open,
    ),
    MatchItem(
      id: 'match_002',
      hostId: 'usr_002',
      venueName: 'Hitech Football Turf',
      location: 'Hitech City, Hyderabad',
      sport: 'Football',
      title: '5-a-side Fast Pace Football',
      description: 'Competitive 5-a-side match. Bibs and FIFA ball provided. Refreshments included.',
      startTime: DateTime.now().add(const Duration(hours: 18)),
      endTime: DateTime.now().add(const Duration(hours: 20)),
      maxPlayers: 10,
      currentPlayers: 9,
      skillLevelRequired: 'All Levels',
      pricePerPlayer: 200.0,
      status: MatchStatus.open,
    ),
    MatchItem(
      id: 'match_003',
      hostId: 'usr_003',
      venueName: 'Gachibowli Badminton Arena',
      location: 'Gachibowli, Hyderabad',
      sport: 'Badminton',
      title: 'Doubles Badminton Knockout',
      description: 'Synthetic indoor court. Feather shuttles. Looking for 1 more player for doubles.',
      startTime: DateTime.now().add(const Duration(days: 2, hours: 4)),
      endTime: DateTime.now().add(const Duration(days: 2, hours: 6)),
      maxPlayers: 4,
      currentPlayers: 3,
      skillLevelRequired: 'Advanced',
      pricePerPlayer: 180.0,
      status: MatchStatus.open,
    ),
    MatchItem(
      id: 'match_004',
      hostId: 'usr_004',
      venueName: 'Jubilee Tennis Club',
      location: 'Jubilee Hills, Hyderabad',
      sport: 'Tennis',
      title: 'Clay Court Weekend Singles',
      description: 'Casual rally and best of 3 sets match on clay court.',
      startTime: DateTime.now().add(const Duration(days: 3, hours: 1)),
      endTime: DateTime.now().add(const Duration(days: 3, hours: 3)),
      maxPlayers: 2,
      currentPlayers: 1,
      skillLevelRequired: 'Intermediate',
      pricePerPlayer: 350.0,
      status: MatchStatus.open,
    ),
  ];

  @override
  Future<List<MatchItem>> getMatches({String? sport, String? search}) async {
    // Try to fetch from API if matches endpoint exists, else serve reactive cache
    try {
      final response = await apiClient.get('/matches');
      if (response.isSuccess && response.data != null) {
        final list = (response.data as List).map((e) => MatchItem.fromJson(e)).toList();
        if (list.isNotEmpty) return list;
      }
    } catch (_) {
      // API fallback
    }

    var result = List<MatchItem>.from(_matches);
    if (sport != null && sport.isNotEmpty && sport.toLowerCase() != 'all') {
      result = result.where((m) => m.sport.toLowerCase() == sport.toLowerCase()).toList();
    }
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      result = result.where((m) => 
        m.title.toLowerCase().contains(q) || 
        m.sport.toLowerCase().contains(q) || 
        m.venueName.toLowerCase().contains(q) ||
        m.location.toLowerCase().contains(q)
      ).toList();
    }
    return result;
  }

  @override
  Future<MatchItem?> getMatchById(String id) async {
    try {
      final response = await apiClient.get('/matches/$id');
      if (response.isSuccess && response.data != null) {
        return MatchItem.fromJson(response.data);
      }
    } catch (_) {}

    return _matches.firstWhere((m) => m.id == id, orElse: () => _matches.first);
  }

  @override
  Future<bool> hostMatch({
    required String title,
    required String sport,
    required int maxPlayers,
    required DateTime startTime,
    required DateTime endTime,
    required double pricePerPlayer,
    required String venueName,
    required String location,
    String? venueId,
    String? description,
    String? skillLevel,
  }) async {
    final newMatch = MatchItem(
      id: 'match_${DateTime.now().millisecondsSinceEpoch}',
      hostId: 'current_user',
      venueId: venueId,
      venueName: venueName,
      location: location,
      sport: sport,
      title: title,
      description: description ?? '',
      startTime: startTime,
      endTime: endTime,
      maxPlayers: maxPlayers,
      currentPlayers: 1,
      skillLevelRequired: skillLevel ?? 'All Levels',
      pricePerPlayer: pricePerPlayer,
      status: MatchStatus.open,
    );

    try {
      final response = await apiClient.post('/matches', data: {
        'title': title,
        'sport': sport,
        'maxPlayers': maxPlayers,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'pricePerPlayer': pricePerPlayer,
        'venueId': venueId,
        'description': description,
      });
      if (response.isSuccess) {
        _matches.insert(0, newMatch);
        return true;
      }
    } catch (_) {}

    _matches.insert(0, newMatch);
    return true;
  }

  @override
  Future<bool> joinMatch(String matchId) async {
    try {
      final response = await apiClient.post('/matches/$matchId/join');
      if (response.isSuccess) return true;
    } catch (_) {}

    final index = _matches.indexWhere((m) => m.id == matchId);
    if (index != -1) {
      final m = _matches[index];
      if (m.currentPlayers < m.maxPlayers) {
        _matches[index] = MatchItem(
          id: m.id,
          hostId: m.hostId,
          venueId: m.venueId,
          venueName: m.venueName,
          location: m.location,
          sport: m.sport,
          title: m.title,
          description: m.description,
          startTime: m.startTime,
          endTime: m.endTime,
          maxPlayers: m.maxPlayers,
          currentPlayers: m.currentPlayers + 1,
          skillLevelRequired: m.skillLevelRequired,
          pricePerPlayer: m.pricePerPlayer,
          status: (m.currentPlayers + 1 >= m.maxPlayers) ? MatchStatus.full : MatchStatus.open,
        );
        return true;
      }
    }
    return false;
  }
}

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return MatchRepositoryImpl(apiClient: apiClient);
});

final matchesFilterSportProvider = StateProvider<String>((ref) => 'All');
final matchesSearchQueryProvider = StateProvider<String>((ref) => '');

final matchesListProvider = FutureProvider.autoDispose<List<MatchItem>>((ref) async {
  final repo = ref.watch(matchRepositoryProvider);
  final sport = ref.watch(matchesFilterSportProvider);
  final search = ref.watch(matchesSearchQueryProvider);
  return repo.getMatches(sport: sport, search: search);
});

