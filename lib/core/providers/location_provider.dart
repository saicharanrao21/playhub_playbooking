import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/location_service.dart';
import '../../app/bootstrap/bootstrap.dart';

@immutable
class UserLocation {
  final double latitude;
  final double longitude;
  final String locationName;
  final bool isGps;
  final double radiusKm;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.locationName,
    this.isGps = false,
    this.radiusKm = 10.0,
  });

  UserLocation copyWith({
    double? latitude,
    double? longitude,
    String? locationName,
    bool? isGps,
    double? radiusKm,
  }) {
    return UserLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      isGps: isGps ?? this.isGps,
      radiusKm: radiusKm ?? this.radiusKm,
    );
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final userLocationProvider = StateNotifierProvider<UserLocationNotifier, UserLocation>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return UserLocationNotifier(locationService, ref);
});

class UserLocationNotifier extends StateNotifier<UserLocation> {
  final LocationService _locationService;
  final Ref _ref;

  UserLocationNotifier(this._locationService, this._ref)
      : super(const UserLocation(
          latitude: 17.4401, // Default Hyderabad center
          longitude: 78.3489,
          locationName: 'Hyderabad',
          isGps: false,
          radiusKm: 10.0,
        ));

  /// Attempts to detect user's live GPS coordinates.
  Future<bool> detectGpsLocation() async {
    final pos = await _locationService.getCurrentPosition();
    if (pos == null) return false;

    // Call reverse geocode API to get clean area/city name
    String areaName = 'Current Location';
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.get<Map<String, dynamic>>(
        '/discovery/geocode/reverse',
        queryParameters: {
          'latitude': pos.latitude,
          'longitude': pos.longitude,
        },
      );
      if (response.isSuccess && response.data != null) {
        areaName = response.data!['city'] ?? response.data!['formattedAddress'] ?? 'GPS Location';
      }
    } catch (_) {}

    state = state.copyWith(
      latitude: pos.latitude,
      longitude: pos.longitude,
      locationName: areaName,
      isGps: true,
    );

    return true;
  }

  void setManualLocation(double lat, double lng, String name) {
    state = state.copyWith(
      latitude: lat,
      longitude: lng,
      locationName: name,
      isGps: false,
    );
  }

  void updateRadius(double radiusKm) {
    state = state.copyWith(radiusKm: radiusKm);
  }
}
