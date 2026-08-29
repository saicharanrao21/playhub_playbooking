import 'package:flutter/foundation.dart';

enum PartnerKYCStatus {
  draft,
  submitted,
  underReview,
  approved,
  rejected,
  resubmissionRequired;

  String get label {
    switch (this) {
      case PartnerKYCStatus.draft:
        return 'Draft';
      case PartnerKYCStatus.submitted:
        return 'Submitted';
      case PartnerKYCStatus.underReview:
        return 'Under Review';
      case PartnerKYCStatus.approved:
        return 'Approved & Active';
      case PartnerKYCStatus.rejected:
        return 'Rejected';
      case PartnerKYCStatus.resubmissionRequired:
        return 'Resubmission Required';
    }
  }
}

enum PartnerFacilityStatus {
  active,
  inactive,
  maintenance;

  String get label {
    switch (this) {
      case PartnerFacilityStatus.active:
        return 'Active';
      case PartnerFacilityStatus.inactive:
        return 'Inactive';
      case PartnerFacilityStatus.maintenance:
        return 'Under Maintenance';
    }
  }

  static PartnerFacilityStatus fromString(String? val) {
    switch (val?.toUpperCase()) {
      case 'INACTIVE':
        return PartnerFacilityStatus.inactive;
      case 'MAINTENANCE':
        return PartnerFacilityStatus.maintenance;
      case 'ACTIVE':
      default:
        return PartnerFacilityStatus.active;
    }
  }
}

@immutable
class PartnerOrganization {
  final String id;
  final String name;
  final String slug;
  final String status;
  final List<String> roles;
  final List<PartnerBusiness> businesses;
  final PartnerKYCStatus kycStatus;
  final String? panNumber;
  final String? gstNumber;
  final String? accountHolderName;
  final String? accountNumber;
  final String? ifscCode;
  final String? bankName;

  const PartnerOrganization({
    required this.id,
    required this.name,
    required this.slug,
    required this.status,
    required this.roles,
    this.businesses = const [],
    this.kycStatus = PartnerKYCStatus.draft,
    this.panNumber,
    this.gstNumber,
    this.accountHolderName,
    this.accountNumber,
    this.ifscCode,
    this.bankName,
  });

  factory PartnerOrganization.fromJson(Map<String, dynamic> json) {
    final org = json['organization'] as Map<String, dynamic>? ?? json;
    final businessesList = (org['businesses'] as List<dynamic>?)
            ?.map((b) => PartnerBusiness.fromJson(b as Map<String, dynamic>))
            .toList() ??
        const [];

    final rolesList = (json['roles'] as List<dynamic>?)
            ?.map((r) => r.toString())
            .toList() ??
        const ['PARTNER_OWNER'];

    return PartnerOrganization(
      id: org['id']?.toString() ?? '',
      name: org['name']?.toString() ?? '',
      slug: org['slug']?.toString() ?? '',
      status: org['status']?.toString() ?? 'ACTIVE',
      roles: rolesList,
      businesses: businessesList,
      kycStatus: _parseKYCStatus(org['kycStatus']?.toString()),
      panNumber: org['panNumber']?.toString(),
      gstNumber: org['gstNumber']?.toString(),
      accountHolderName: org['accountHolderName']?.toString(),
      accountNumber: org['accountNumber']?.toString(),
      ifscCode: org['ifscCode']?.toString(),
      bankName: org['bankName']?.toString(),
    );
  }

  static PartnerKYCStatus _parseKYCStatus(String? val) {
    switch (val?.toUpperCase()) {
      case 'SUBMITTED':
        return PartnerKYCStatus.submitted;
      case 'UNDER_REVIEW':
        return PartnerKYCStatus.underReview;
      case 'APPROVED':
        return PartnerKYCStatus.approved;
      case 'REJECTED':
        return PartnerKYCStatus.rejected;
      case 'RESUBMISSION_REQUIRED':
        return PartnerKYCStatus.resubmissionRequired;
      case 'DRAFT':
      default:
        return PartnerKYCStatus.draft;
    }
  }
}

@immutable
class PartnerBusiness {
  final String id;
  final String organizationId;
  final String legalName;
  final String displayName;
  final String status;
  final List<PartnerVenue> venues;

  const PartnerBusiness({
    required this.id,
    required this.organizationId,
    required this.legalName,
    required this.displayName,
    required this.status,
    this.venues = const [],
  });

  factory PartnerBusiness.fromJson(Map<String, dynamic> json) {
    final venuesList = (json['venues'] as List<dynamic>?)
            ?.map((v) => PartnerVenue.fromJson(v as Map<String, dynamic>))
            .toList() ??
        const [];

    return PartnerBusiness(
      id: json['id']?.toString() ?? '',
      organizationId: json['organizationId']?.toString() ?? '',
      legalName: json['legalName']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
      venues: venuesList,
    );
  }
}

@immutable
class PartnerVenue {
  final String id;
  final String businessId;
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
  final String status;
  final List<PartnerFacility> facilities;

  const PartnerVenue({
    required this.id,
    required this.businessId,
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
    this.timezone = 'Asia/Kolkata',
    this.status = 'ACTIVE',
    this.facilities = const [],
  });

  factory PartnerVenue.fromJson(Map<String, dynamic> json) {
    final facilitiesList = (json['facilities'] as List<dynamic>?)
            ?.map((f) => PartnerFacility.fromJson(f as Map<String, dynamic>))
            .toList() ??
        const [];

    return PartnerVenue(
      id: json['id']?.toString() ?? '',
      businessId: json['businessId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      country: json['country']?.toString() ?? 'India',
      postalCode: json['postalCode']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      timezone: json['timezone']?.toString() ?? 'Asia/Kolkata',
      status: json['status']?.toString() ?? 'ACTIVE',
      facilities: facilitiesList,
    );
  }
}

@immutable
class PartnerFacility {
  final String id;
  final String venueId;
  final String name;
  final String? description;
  final int capacity;
  final PartnerFacilityStatus status;
  final String categoryId;
  final String? categoryName;
  final String? activityId;
  final String? activityName;

  const PartnerFacility({
    required this.id,
    required this.venueId,
    required this.name,
    this.description,
    this.capacity = 10,
    this.status = PartnerFacilityStatus.active,
    required this.categoryId,
    this.categoryName,
    this.activityId,
    this.activityName,
  });

  factory PartnerFacility.fromJson(Map<String, dynamic> json) {
    final cat = json['category'] as Map<String, dynamic>?;
    final act = json['activity'] as Map<String, dynamic>?;

    return PartnerFacility(
      id: json['id']?.toString() ?? '',
      venueId: json['venueId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      capacity: (json['capacity'] as num?)?.toInt() ?? 10,
      status: PartnerFacilityStatus.fromString(json['status']?.toString()),
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: cat?['name']?.toString(),
      activityId: json['activityId']?.toString(),
      activityName: act?['name']?.toString(),
    );
  }
}

@immutable
class PartnerBookingItem {
  final String id;
  final String organizationId;
  final String facilityId;
  final String facilityName;
  final String venueName;
  final String userId;
  final String customerName;
  final String customerPhone;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final double totalPrice;
  final String currency;
  final String paymentStatus;

  const PartnerBookingItem({
    required this.id,
    required this.organizationId,
    required this.facilityId,
    required this.facilityName,
    required this.venueName,
    required this.userId,
    required this.customerName,
    required this.customerPhone,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.totalPrice,
    this.currency = 'INR',
    this.paymentStatus = 'CAPTURED',
  });

  factory PartnerBookingItem.fromJson(Map<String, dynamic> json) {
    final facility = json['facility'] as Map<String, dynamic>?;
    final venue = facility?['venue'] as Map<String, dynamic>?;
    final user = json['user'] as Map<String, dynamic>?;
    final payments = json['payments'] as List<dynamic>?;
    final latestPayment = payments != null && payments.isNotEmpty
        ? payments.first as Map<String, dynamic>?
        : null;

    return PartnerBookingItem(
      id: json['id']?.toString() ?? '',
      organizationId: json['organizationId']?.toString() ?? '',
      facilityId: json['facilityId']?.toString() ?? '',
      facilityName: facility?['name']?.toString() ?? 'Sports Facility',
      venueName: venue?['name']?.toString() ?? 'Sports Complex',
      userId: json['userId']?.toString() ?? '',
      customerName: user?['fullName']?.toString() ?? user?['email']?.toString() ?? 'Customer',
      customerPhone: user?['phoneNumber']?.toString() ?? '+91 98765 43210',
      startTime: DateTime.tryParse(json['startTime']?.toString() ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['endTime']?.toString() ?? '') ?? DateTime.now().add(const Duration(hours: 1)),
      status: json['status']?.toString() ?? 'CONFIRMED',
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 800.0,
      currency: json['currency']?.toString() ?? 'INR',
      paymentStatus: latestPayment?['status']?.toString() ?? 'CAPTURED',
    );
  }

  String get statusLabel {
    switch (status.toUpperCase()) {
      case 'PENDING': return 'Pending Approval';
      case 'CONFIRMED': return 'Confirmed';
      case 'CHECKED_IN': return 'Checked In';
      case 'COMPLETED': return 'Completed';
      case 'CANCELLED': return 'Cancelled';
      case 'REJECTED': return 'Rejected';
      case 'NO_SHOW': return 'No Show';
      default: return status;
    }
  }
}

class OnboardPartnerRequest {
  final String organizationName;
  final String legalName;
  final String displayName;
  final String? panNumber;
  final String? gstNumber;
  final String? accountHolderName;
  final String? accountNumber;
  final String? ifscCode;
  final String? bankName;

  const OnboardPartnerRequest({
    required this.organizationName,
    required this.legalName,
    required this.displayName,
    this.panNumber,
    this.gstNumber,
    this.accountHolderName,
    this.accountNumber,
    this.ifscCode,
    this.bankName,
  });

  Map<String, dynamic> toJson() => {
        'organizationName': organizationName,
        'legalName': legalName,
        'displayName': displayName,
        if (panNumber != null && panNumber!.isNotEmpty) 'panNumber': panNumber,
        if (gstNumber != null && gstNumber!.isNotEmpty) 'gstNumber': gstNumber,
        if (accountHolderName != null && accountHolderName!.isNotEmpty) 'accountHolderName': accountHolderName,
        if (accountNumber != null && accountNumber!.isNotEmpty) 'accountNumber': accountNumber,
        if (ifscCode != null && ifscCode!.isNotEmpty) 'ifscCode': ifscCode,
        if (bankName != null && bankName!.isNotEmpty) 'bankName': bankName,
      };
}

class CreatePartnerVenueRequest {
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

  const CreatePartnerVenueRequest({
    required this.name,
    required this.slug,
    this.description,
    required this.address,
    required this.city,
    required this.state,
    this.country = 'India',
    required this.postalCode,
    this.latitude,
    this.longitude,
    this.timezone = 'Asia/Kolkata',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'slug': slug,
        if (description != null) 'description': description,
        'address': address,
        'city': city,
        'state': state,
        'country': country,
        'postalCode': postalCode,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'timezone': timezone,
      };
}

class CreatePartnerFacilityRequest {
  final String name;
  final String? description;
  final int capacity;
  final String categoryId;
  final String? activityId;
  final String status;

  const CreatePartnerFacilityRequest({
    required this.name,
    this.description,
    required this.capacity,
    required this.categoryId,
    this.activityId,
    this.status = 'ACTIVE',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null) 'description': description,
        'capacity': capacity,
        'categoryId': categoryId,
        if (activityId != null) 'activityId': activityId,
        'status': status,
      };
}

@immutable
class PricingRule {
  final String id;
  final String name;
  final double basePrice;
  final String currency;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final String? startTime;
  final String? endTime;
  final List<String> daysOfWeek;
  final int priority;
  final bool isActive;

  const PricingRule({
    required this.id,
    required this.name,
    required this.basePrice,
    this.currency = 'INR',
    this.effectiveFrom,
    this.effectiveTo,
    this.startTime,
    this.endTime,
    this.daysOfWeek = const [],
    this.priority = 0,
    this.isActive = true,
  });

  factory PricingRule.fromJson(Map<String, dynamic> json) {
    return PricingRule(
      id: json['id'],
      name: json['name'],
      basePrice: (json['basePrice'] as num).toDouble(),
      currency: json['currency'] ?? 'INR',
      effectiveFrom: json['effectiveFrom'] != null ? DateTime.parse(json['effectiveFrom']) : null,
      effectiveTo: json['effectiveTo'] != null ? DateTime.parse(json['effectiveTo']) : null,
      startTime: json['startTime'],
      endTime: json['endTime'],
      daysOfWeek: (json['daysOfWeek'] as List? ?? []).map((e) => e.toString()).toList(),
      priority: json['priority'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }
}

class CreatePricingRuleRequest {
  final String name;
  final double basePrice;
  final String? startTime;
  final String? endTime;
  final List<String>? daysOfWeek;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final int priority;

  const CreatePricingRuleRequest({
    required this.name,
    required this.basePrice,
    this.startTime,
    this.endTime,
    this.daysOfWeek,
    this.effectiveFrom,
    this.effectiveTo,
    this.priority = 0,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'basePrice': basePrice,
        if (startTime != null) 'startTime': startTime,
        if (endTime != null) 'endTime': endTime,
        if (daysOfWeek != null) 'daysOfWeek': daysOfWeek,
        if (effectiveFrom != null) 'effectiveFrom': effectiveFrom!.toIso8601String(),
        if (effectiveTo != null) 'effectiveTo': effectiveTo!.toIso8601String(),
        'priority': priority,
      };
}
