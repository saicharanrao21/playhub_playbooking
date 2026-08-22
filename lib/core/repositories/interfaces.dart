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
}

abstract class ICityRepository {
  Future<List<City>> getCities();
}

abstract class IActivityRepository {
  Future<List<Activity>> getActivities({String? categoryId});
}

abstract class IDiscoveryRepository {
  Future<List<Venue>> discoverVenues({
    String? query,
    String? cityId,
    String? categoryId,
    String? activityId,
  });
}
