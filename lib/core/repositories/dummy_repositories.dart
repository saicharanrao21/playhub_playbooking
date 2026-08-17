import '../models/app_models.dart';
import 'interfaces.dart';

class DummyData {
  static final categories = [
    Category(id: '1', name: 'Cricket', icon: 'sports_cricket'),
    Category(id: '2', name: 'Football', icon: 'sports_soccer'),
    Category(id: '3', name: 'Badminton', icon: 'sports_tennis'),
    Category(id: '4', name: 'Swimming', icon: 'pool'),
    Category(id: '5', name: 'Gym', icon: 'fitness_center'),
  ];

  static final cities = [
    City(id: '1', name: 'Hyderabad'),
    City(id: '2', name: 'Bangalore'),
    City(id: '3', name: 'Mumbai'),
    City(id: '4', name: 'Delhi'),
  ];

  static final venues = [
    Venue(
      id: '1',
      businessId: 'b1',
      name: 'Skyline Cricket Ground',
      description:
          'Premium cricket ground with floodlights and professional pitch.',
      address: 'Madhapur, Hyderabad',
      city: 'Hyderabad',
      latitude: 17.4483,
      longitude: 78.3915,
      imageUrls: [
        'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=800',
      ],
      amenities: ['Floodlights', 'Parking', 'Changing Rooms', 'Water'],
      rating: 4.5,
      reviewCount: 120,
      categoryId: '1',
    ),
    Venue(
      id: '2',
      businessId: 'b2',
      name: 'Arena Football Turf',
      description:
          '5-a-side and 7-a-side football turf with high-quality grass.',
      address: 'Kondapur, Hyderabad',
      city: 'Hyderabad',
      latitude: 17.4622,
      longitude: 78.3568,
      imageUrls: [
        'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800',
      ],
      amenities: ['Parking', 'Bibs', 'Shower'],
      rating: 4.8,
      reviewCount: 85,
      categoryId: '2',
    ),
  ];
}

class DummyVenueRepository implements IVenueRepository {
  @override
  Future<List<Venue>> getVenues() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return DummyData.venues;
  }

  @override
  Future<Venue?> getVenueById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return DummyData.venues.firstWhere((v) => v.id == id);
  }

  @override
  Future<List<Venue>> searchVenues(String query) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return DummyData.venues
        .where((v) => v.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<List<Venue>> getVenuesByCategory(String categoryId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return DummyData.venues.where((v) => v.categoryId == categoryId).toList();
  }
}

class DummyAuthRepository implements IAuthRepository {
  User? _currentUser;

  @override
  Future<User?> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = User(
      id: 'u1',
      name: 'John Doe',
      email: email,
      role: UserRole.customer,
    );
    return _currentUser;
  }

  @override
  Future<User?> register(String name, String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = User(
      id: 'u2',
      name: name,
      email: email,
      role: UserRole.customer,
    );
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
  }

  @override
  Future<User?> getCurrentUser() async {
    return _currentUser;
  }
}

class DummyCategoryRepository implements ICategoryRepository {
  @override
  Future<List<Category>> getCategories() async {
    return DummyData.categories;
  }
}

class DummyCityRepository implements ICityRepository {
  @override
  Future<List<City>> getCities() async {
    return DummyData.cities;
  }
}
