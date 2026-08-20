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
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
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
    final rolesList = (json['roles'] as List?)?.map((r) => r['name'] as String).toList() ?? [];
    final permissionsSet = <String>{};
    
    if (json['roles'] != null) {
      for (final role in json['roles']) {
        final perms = role['permissions'] as List?;
        if (perms != null) {
          for (final p in perms) {
            permissionsSet.add('${p['action']}:${p['resource']}');
          }
        }
      }
    }

    return OrganizationMembership(
      id: json['id'],
      organizationId: json['organizationId'],
      organization: OrganizationInfo.fromJson(json['organization']),
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
    final memberships = (json['memberships'] as List?)
            ?.map((m) => OrganizationMembership.fromJson(m))
            .toList() ??
        [];

    // Resolve global role: if any membership has ADMIN/PLATFORM_ADMIN, they are admin globally for UI purposes.
    UserRole resolvedRole = UserRole.customer;
    for (final m in memberships) {
      if (m.roles.contains('ADMIN') || m.roles.contains('PLATFORM_ADMIN')) {
        resolvedRole = UserRole.admin;
        break;
      }
      if (m.roles.contains('BUSINESS_OWNER') && resolvedRole != UserRole.admin) {
        resolvedRole = UserRole.businessOwner;
      }
    }

    return UserIdentity(
      id: json['id'],
      email: json['email'],
      name: json['fullName'] ?? '',
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
