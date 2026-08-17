import 'app_models.dart';

/// Represents a secure user identity.
class UserIdentity {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final AccountStatus status;

  const UserIdentity({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.status = AccountStatus.active,
  });

  factory UserIdentity.fromUser(User user) {
    return UserIdentity(
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
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
