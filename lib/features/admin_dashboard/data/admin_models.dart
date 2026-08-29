import 'package:flutter/foundation.dart';

@immutable
class AdminPartner {
  final String id;
  final String name;
  final String slug;
  final String status;
  final String kycStatus;
  final DateTime createdAt;
  final List<dynamic> businesses;
  final String? ownerName;
  final String? ownerEmail;

  const AdminPartner({
    required this.id,
    required this.name,
    required this.slug,
    required this.status,
    required this.kycStatus,
    required this.createdAt,
    this.businesses = const [],
    this.ownerName,
    this.ownerEmail,
  });

  factory AdminPartner.fromJson(Map<String, dynamic> json) {
    final memberships = json['memberships'] as List? ?? [];
    final owner = memberships.isNotEmpty ? memberships.first['user'] : null;

    return AdminPartner(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      status: json['status'] ?? '',
      kycStatus: json['kycStatus'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      businesses: json['businesses'] ?? [],
      ownerName: owner?['fullName'],
      ownerEmail: owner?['email'],
    );
  }
}

@immutable
class AdminAuditLog {
  final String id;
  final String action;
  final String? resource;
  final String? resourceId;
  final String status;
  final DateTime createdAt;
  final String? userName;
  final String? orgName;

  const AdminAuditLog({
    required this.id,
    required this.action,
    this.resource,
    this.resourceId,
    required this.status,
    required this.createdAt,
    this.userName,
    this.orgName,
  });

  factory AdminAuditLog.fromJson(Map<String, dynamic> json) {
    return AdminAuditLog(
      id: json['id'] ?? '',
      action: json['action'] ?? '',
      resource: json['resource'],
      resourceId: json['resourceId'],
      status: json['status'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      userName: json['user']?['fullName'] ?? json['user']?['email'],
      orgName: json['organization']?['name'],
    );
  }
}
