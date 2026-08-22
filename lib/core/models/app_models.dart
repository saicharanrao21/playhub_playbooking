class User {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;
  final UserRole role;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.role,
  });
}

enum UserRole { customer, businessOwner, admin }

class Business {
  final String id;
  final String name;
  final String ownerId;
  final String description;
  final String? logoUrl;
  final bool isApproved;

  Business({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.description,
    this.logoUrl,
    this.isApproved = false,
  });
}

class Venue {
  final String id;
  final String businessId;
  final String name;
  final String? description;
  final String address;
  final String city;
  final String? cityId;
  final double? latitude;
  final double? longitude;
  final List<String> imageUrls;
  final List<String> amenities;
  final double rating;
  final int reviewCount;
  final String? categoryId;
  final List<Facility>? facilities; 

  Venue({
    required this.id,
    required this.businessId,
    required this.name,
    this.description,
    required this.address,
    required this.city,
    this.cityId,
    this.latitude,
    this.longitude,
    required this.imageUrls,
    required this.amenities,
    required this.rating,
    required this.reviewCount,
    this.categoryId,
    this.facilities,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'],
      businessId: json['businessId'],
      name: json['name'],
      description: json['description'],
      address: json['address'],
      city: json['city'] ?? '',
      cityId: json['cityId'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      imageUrls: (json['imageUrls'] as List?)?.map((e) => e as String).toList() ?? [],
      amenities: (json['amenities'] as List?)?.map((e) => e as String).toList() ?? [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] ?? 0,
      categoryId: json['categoryId'],
      facilities: (json['facilities'] as List?)?.map((e) => Facility.fromJson(e)).toList(),
    );
  }
}

class Facility {
  final String id;
  final String name;
  final String? description;
  final String? categoryId;
  final String? activityId;

  Facility({
    required this.id,
    required this.name,
    this.description,
    this.categoryId,
    this.activityId,
  });

  factory Facility.fromJson(Map<String, dynamic> json) {
    return Facility(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      categoryId: json['categoryId'],
      activityId: json['activityId'],
    );
  }
}

class Activity {
  final String id;
  final String name;
  final String slug;
  final String? categoryId;
  final String? icon;

  Activity({
    required this.id,
    required this.name,
    required this.slug,
    this.categoryId,
    this.icon,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      categoryId: json['categoryId'],
      icon: json['icon'],
    );
  }
}

class Category {
  final String id;
  final String name;
  final String slug;
  final String? icon;
  final List<Activity>? activities;

  Category({
    required this.id, 
    required this.name, 
    required this.slug,
    this.icon,
    this.activities,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      icon: json['icon'],
      activities: (json['activities'] as List?)?.map((e) => Activity.fromJson(e)).toList(),
    );
  }
}

class Slot {
  final String id;
  final String venueId;
  final DateTime startTime;
  final DateTime endTime;
  final double price;
  final bool isAvailable;

  Slot({
    required this.id,
    required this.venueId,
    required this.startTime,
    required this.endTime,
    required this.price,
    this.isAvailable = true,
  });
}

class Booking {
  final String id;
  final String userId;
  final String venueId;
  final String slotId;
  final DateTime bookingDate;
  final BookingStatus status;
  final double totalPrice;

  Booking({
    required this.id,
    required this.userId,
    required this.venueId,
    required this.slotId,
    required this.bookingDate,
    required this.status,
    required this.totalPrice,
  });
}

enum BookingStatus { pending, confirmed, cancelled, completed }

class Review {
  final String id;
  final String userId;
  final String venueId;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.venueId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}

class City {
  final String id;
  final String name;
  final String slug;
  final String? state;

  City({
    required this.id, 
    required this.name,
    required this.slug,
    this.state,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      state: json['state'],
    );
  }
}

class Notification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;

  Notification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
  });
}
