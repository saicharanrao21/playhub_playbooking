import '../models/app_models.dart';

abstract class IVenueRepository {
  Future<List<Venue>> getVenues();
  Future<Venue?> getVenueById(String id);
  Future<List<Venue>> searchVenues(String query);
  Future<List<Venue>> getVenuesByCategory(String categoryId);
}

abstract class IBookingRepository {
  Future<List<Booking>> getBookingsByUserId(String userId);
  Future<Booking> createBooking(Booking booking);
  Future<void> cancelBooking(String bookingId);
}

abstract class IAuthRepository {
  Future<User?> login(String email, String password);
  Future<User?> register(String name, String email, String password);
  Future<void> logout();
  Future<User?> getCurrentUser();
}

abstract class ICategoryRepository {
  Future<List<Category>> getCategories();
  Future<Category?> createCategory(Map<String, dynamic> data);
  Future<Category?> updateCategory(String id, Map<String, dynamic> data);
}

abstract class ICityRepository {
  Future<List<City>> getCities();
  Future<City?> createCity(Map<String, dynamic> data);
  Future<City?> updateCity(String id, Map<String, dynamic> data);
}

abstract class IActivityRepository {
  Future<List<Activity>> getActivities({String? categoryId});
  Future<Activity?> createActivity(Map<String, dynamic> data);
  Future<Activity?> updateActivity(String id, Map<String, dynamic> data);
}

abstract class IDiscoveryRepository {
  Future<List<Venue>> discoverVenues({
    String? query,
    String? cityId,
    String? categoryId,
    String? activityId,
  });

  Future<List<Venue>> getNearbyVenues({
    double? latitude,
    double? longitude,
    double radius = 10.0,
    String? query,
    String? cityId,
    String? categoryId,
    String? activityId,
    String sortBy = 'distance',
  });
}
