import 'dart:math';
import 'package:geolocator/geolocator.dart';
import '../logging/app_logger.dart';

class LocationService {
  /// Checks if location services are enabled and permissions granted.
  Future<bool> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      AppLogger.warning('Location services are disabled on device.');
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        AppLogger.warning('Location permissions denied by user.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      AppLogger.warning('Location permissions permanently denied.');
      return false;
    }

    return true;
  }

  /// Fetches user's current GPS position.
  Future<Position?> getCurrentPosition() async {
    final hasPermission = await checkPermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to get current GPS position', e);
      return null;
    }
  }

  /// Exact Haversine distance in meters between two lat/lng points.
  double calculateDistanceMeters(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadiusMeters = 6371008.8;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLng / 2) * sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  /// Formats distance in meters into human-readable string (e.g., "350 m", "1.2 km").
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    final km = meters / 1000.0;
    return '${km.toStringAsFixed(1)} km';
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180.0;
  }
}
