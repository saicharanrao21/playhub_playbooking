import 'app_models.dart';

/// Represents a secure user identity.
class UserIdentity {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final AccountStatus status;
  final String? organizationId;
  final List<String> permissions;

  const UserIdentity({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.status = AccountStatus.active,
    this.organizationId,
    this.permissions = const [],
  });

  factory UserIdentity.fromUser(User user) {
    return UserIdentity(
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
    );
  }

  factory UserIdentity.fromJson(Map<String, dynamic> json) {
    String? orgId;
    UserRole resolvedRole = UserRole.customer;
    final Set<String> resolvedPermissions = {};

    if (json['memberships'] != null && (json['memberships'] as List).isNotEmpty) {
      // For now, we take the first membership as the primary context
      final membership = json['memberships'][0];
      orgId = membership['organizationId'];
      
      final roles = membership['roles'] as List?;
      if (roles != null) {
        for (final role in roles) {
          final roleName = role['name'] as String;
          if (roleName == 'ADMIN' || roleName == 'PLATFORM_ADMIN') {
            resolvedRole = UserRole.admin;
          } else if (roleName == 'BUSINESS_OWNER' && resolvedRole != UserRole.admin) {
            resolvedRole = UserRole.businessOwner;
          }

          final perms = role['permissions'] as List?;
          if (perms != null) {
            for (final p in perms) {
              resolvedPermissions.add('${p['action']}:${p['resource']}');
            }
          }
        }
      }
    }

    return UserIdentity(
      id: json['id'],
      email: json['email'],
      name: json['fullName'] ?? '',
      role: resolvedRole,
      organizationId: orgId,
      permissions: resolvedPermissions.toList(),
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
