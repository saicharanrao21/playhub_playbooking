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

enum MediaType { image, document }

class Media {
  final String id;
  final String url;
  final MediaType type;
  final int displayOrder;

  Media({
    required this.id,
    required this.url,
    required this.type,
    this.displayOrder = 0,
  });

  factory Media.fromJson(Map<String, dynamic> json) {
    return Media(
      id: json['id'],
      url: json['url'],
      type: MediaType.values.byName(json['type'].toString().toLowerCase()),
      displayOrder: json['displayOrder'] ?? 0,
    );
  }
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
  final List<Media> media;
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
    required this.media,
    required this.amenities,
    required this.rating,
    required this.reviewCount,
    this.categoryId,
    this.facilities,
  });

  List<String> get imageUrls => media
      .where((m) => m.type == MediaType.image)
      .map((m) => m.url)
      .toList();

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
      media: (json['media'] as List?)?.map((e) => Media.fromJson(e)).toList() ?? [],
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
  final List<Media> media;

  Facility({
    required this.id,
    required this.name,
    this.description,
    this.categoryId,
    this.activityId,
    required this.media,
  });

  List<String> get imageUrls => media
      .where((m) => m.type == MediaType.image)
      .map((m) => m.url)
      .toList();

  factory Facility.fromJson(Map<String, dynamic> json) {
    return Facility(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      categoryId: json['categoryId'],
      activityId: json['activityId'],
      media: (json['media'] as List?)?.map((e) => Media.fromJson(e)).toList() ?? [],
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

enum MatchStatus { open, full, cancelled, completed }

class MatchItem {
  final String id;
  final String hostId;
  final String? venueId;
  final String venueName;
  final String location;
  final String sport;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final int maxPlayers;
  final int currentPlayers;
  final String skillLevelRequired;
  final double pricePerPlayer;
  final MatchStatus status;
  final bool isPrivate;

  MatchItem({
    required this.id,
    required this.hostId,
    this.venueId,
    required this.venueName,
    required this.location,
    required this.sport,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.maxPlayers,
    this.currentPlayers = 1,
    required this.skillLevelRequired,
    required this.pricePerPlayer,
    this.status = MatchStatus.open,
    this.isPrivate = false,
  });

  factory MatchItem.fromJson(Map<String, dynamic> json) {
    return MatchItem(
      id: json['id'] ?? '',
      hostId: json['hostId'] ?? '',
      venueId: json['venueId'],
      venueName: json['venueName'] ?? 'PlayHub Arena',
      location: json['location'] ?? 'Hyderabad',
      sport: json['sport'] ?? 'Football',
      title: json['title'] ?? 'Sports Match',
      description: json['description'] ?? '',
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : DateTime.now().add(const Duration(days: 1)),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : DateTime.now().add(const Duration(days: 1, hours: 2)),
      maxPlayers: json['maxPlayers'] ?? 10,
      currentPlayers: json['currentPlayers'] ?? 1,
      skillLevelRequired: json['skillLevelRequired'] ?? 'All Levels',
      pricePerPlayer: (json['pricePerPlayer'] as num?)?.toDouble() ?? 150.0,
      status: MatchStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => MatchStatus.open),
      isPrivate: json['isPrivate'] ?? false,
    );
  }
}

class CommunityItem {
  final String id;
  final String name;
  final String description;
  final String? avatarUrl;
  final String sport;
  final int memberCount;
  final bool isJoined;

  CommunityItem({
    required this.id,
    required this.name,
    required this.description,
    this.avatarUrl,
    required this.sport,
    this.memberCount = 1,
    this.isJoined = false,
  });
}

class CommunityPostItem {
  final String id;
  final String authorName;
  final String? authorAvatar;
  final String communityName;
  final String content;
  final String? imageUrl;
  final int likes;
  final int comments;
  final DateTime createdAt;
  final bool isLiked;

  CommunityPostItem({
    required this.id,
    required this.authorName,
    this.authorAvatar,
    required this.communityName,
    required this.content,
    this.imageUrl,
    this.likes = 0,
    this.comments = 0,
    required this.createdAt,
    this.isLiked = false,
  });
}

class WalletInfo {
  final String id;
  final String userId;
  final double balance;
  final String currency;

  WalletInfo({
    required this.id,
    required this.userId,
    required this.balance,
    this.currency = 'INR',
  });
}

class WalletTransactionItem {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final bool isCredit;
  final DateTime createdAt;

  WalletTransactionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isCredit,
    required this.createdAt,
  });
}

