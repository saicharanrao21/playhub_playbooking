enum BusinessStatus { pendingOnboarding, active, suspended, archived }
enum VenueStatus { draft, pendingApproval, active, suspended, archived }
enum FacilityStatus { active, inactive, maintenance, archived }
enum DayOfWeek { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

class Business {
  final String id;
  final String organizationId;
  final String legalName;
  final String displayName;
  final BusinessStatus status;

  const Business({
    required this.id,
    required this.organizationId,
    required this.legalName,
    required this.displayName,
    required this.status,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'],
      organizationId: json['organizationId'],
      legalName: json['legalName'],
      displayName: json['displayName'],
      status: BusinessStatus.values.byName(_toCamelCase(json['status'])),
    );
  }

  static String _toCamelCase(String status) =>
      status.toLowerCase().replaceAllMapped(RegExp(r'_([a-z])'), (m) => m[1]!.toUpperCase());
}

class Venue {
  final String id;
  final String businessId;
  final String? cityId;
  final String name;
  final String slug;
  final String? description;
  final String address;
  final String city;
  final String state;
  final String country;
  final String postalCode;
  final double? latitude;
  final double? longitude;
  final String timezone;
  final VenueStatus status;
  final List<Facility>? facilities;
  final List<OperatingHours>? operatingHours;

  const Venue({
    required this.id,
    required this.businessId,
    this.cityId,
    required this.name,
    required this.slug,
    this.description,
    required this.address,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    this.latitude,
    this.longitude,
    required this.timezone,
    required this.status,
    this.facilities,
    this.operatingHours,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'],
      businessId: json['businessId'],
      cityId: json['cityId'],
      name: json['name'],
      slug: json['slug'],
      description: json['description'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      postalCode: json['postalCode'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      timezone: json['timezone'],
      status: VenueStatus.values.byName(_toCamelCase(json['status'])),
      facilities: (json['facilities'] as List?)?.map((f) => Facility.fromJson(f)).toList(),
      operatingHours: (json['operatingHours'] as List?)?.map((h) => OperatingHours.fromJson(h)).toList(),
    );
  }

  static String _toCamelCase(String status) =>
      status.toLowerCase().replaceAllMapped(RegExp(r'_([a-z])'), (m) => m[1]!.toUpperCase());
}

class Facility {
  final String id;
  final String venueId;
  final String categoryId;
  final String? activityId;
  final String name;
  final String? description;
  final int? capacity;
  final FacilityStatus status;

  const Facility({
    required this.id,
    required this.venueId,
    required this.categoryId,
    this.activityId,
    required this.name,
    this.description,
    this.capacity,
    required this.status,
  });

  factory Facility.fromJson(Map<String, dynamic> json) {
    return Facility(
      id: json['id'],
      venueId: json['venueId'],
      categoryId: json['categoryId'],
      activityId: json['activityId'],
      name: json['name'],
      description: json['description'],
      capacity: json['capacity'],
      status: FacilityStatus.values.byName(json['status'].toString().toLowerCase()),
    );
  }
}

class OperatingHours {
  final DayOfWeek dayOfWeek;
  final String openingTime;
  final String closingTime;
  final bool isClosed;

  const OperatingHours({
    required this.dayOfWeek,
    required this.openingTime,
    required this.closingTime,
    required this.isClosed,
  });

  factory OperatingHours.fromJson(Map<String, dynamic> json) {
    return OperatingHours(
      dayOfWeek: DayOfWeek.values.byName(json['dayOfWeek'].toString().toLowerCase()),
      openingTime: json['openingTime'],
      closingTime: json['closingTime'],
      isClosed: json['isClosed'],
    );
  }
}
