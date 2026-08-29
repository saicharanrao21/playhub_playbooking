import 'app_models.dart';

/// Represents a summarized organization info for discovery and selection.
class OrganizationInfo {
  final String id;
  final String name;
  final String slug;

  const OrganizationInfo({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory OrganizationInfo.fromJson(Map<String, dynamic> json) {
    return OrganizationInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
    );
  }
}

/// Represents a user's membership in an organization with roles and permissions.
class OrganizationMembership {
  final String id;
  final String organizationId;
  final OrganizationInfo organization;
  final List<String> roles;
  final List<String> permissions;

  const OrganizationMembership({
    required this.id,
    required this.organizationId,
    required this.organization,
    required this.roles,
    required this.permissions,
  });

  factory OrganizationMembership.fromJson(Map<String, dynamic> json) {
    final rolesRaw = json['roles'] as List<dynamic>? ?? [];
    final rolesList = <String>[];
    final permissionsSet = <String>{};

    for (final role in rolesRaw) {
      if (role is Map) {
        if (role['name'] != null) {
          rolesList.add(role['name'].toString());
        }
        final perms = role['permissions'] as List<dynamic>?;
        if (perms != null) {
          for (final p in perms) {
            if (p is Map) {
              permissionsSet.add('${p['action']}:${p['resource']}');
            }
          }
        }
      } else if (role is String) {
        rolesList.add(role);
      }
    }

    final orgMap = json['organization'] is Map
        ? Map<String, dynamic>.from(json['organization'] as Map)
        : <String, dynamic>{'id': json['organizationId']?.toString() ?? '', 'name': 'Organization', 'slug': 'org'};

    return OrganizationMembership(
      id: json['id']?.toString() ?? '',
      organizationId: json['organizationId']?.toString() ?? '',
      organization: OrganizationInfo.fromJson(orgMap),
      roles: rolesList,
      permissions: permissionsSet.toList(),
    );
  }
}

/// Represents a secure user identity.
class UserIdentity {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final AccountStatus status;
  final List<OrganizationMembership> memberships;

  const UserIdentity({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.status = AccountStatus.active,
    this.memberships = const [],
  });

  /// Returns the organizationId used for discovery/legacy logic if no explicit context exists.
  String? get primaryOrganizationId => memberships.isNotEmpty ? memberships.first.organizationId : null;

  factory UserIdentity.fromUser(User user) {
    return UserIdentity(
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
    );
  }

  factory UserIdentity.fromJson(Map<String, dynamic> json) {
    final membershipsRaw = json['memberships'] as List<dynamic>? ?? [];
    final memberships = membershipsRaw
        .whereType<Map>()
        .map((m) => OrganizationMembership.fromJson(Map<String, dynamic>.from(m)))
        .toList();

    // Resolve global role: if any membership has ADMIN/PLATFORM_ADMIN, they are admin globally for UI purposes.
    UserRole resolvedRole = UserRole.customer;
    for (final m in memberships) {
      if (m.roles.contains('ADMIN') || m.roles.contains('PLATFORM_ADMIN')) {
        resolvedRole = UserRole.admin;
        break;
      }
      if ((m.roles.contains('BUSINESS_OWNER') || m.roles.contains('PARTNER_OWNER')) && resolvedRole != UserRole.admin) {
        resolvedRole = UserRole.businessOwner;
      }
    }

    return UserIdentity(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: (json['fullName'] ?? json['name'] ?? '').toString(),
      role: resolvedRole,
      memberships: memberships,
    );
  }
}

enum AccountStatus { active, pendingVerification, suspended, disabled, deleted }

/// Represents an active authentication session.
class AuthSession {
  final String accessToken;
  final String refreshToken;
  final UserIdentity identity;
  final DateTime expiresAt;

  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.identity,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
