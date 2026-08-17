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
  final String description;
  final String address;
  final String city;
  final double latitude;
  final double longitude;
  final List<String> imageUrls;
  final List<String> amenities;
  final double rating;
  final int reviewCount;
  final String categoryId;

  Venue({
    required this.id,
    required this.businessId,
    required this.name,
    required this.description,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.imageUrls,
    required this.amenities,
    required this.rating,
    required this.reviewCount,
    required this.categoryId,
  });
}

class Activity {
  final String id;
  final String name;
  final String categoryId;
  final String icon;

  Activity({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.icon,
  });
}

class Category {
  final String id;
  final String name;
  final String icon;

  Category({required this.id, required this.name, required this.icon});
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

  City({required this.id, required this.name});
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
