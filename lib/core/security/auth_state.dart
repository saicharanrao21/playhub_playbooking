import '../models/app_models.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  authenticating,
  error,
}

class AuthState {
  final AuthStatus status;
  final String? userId;
  final UserRole? role;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.userId,
    this.role,
    this.errorMessage,
  });

  const AuthState.authenticated({
    required String userId,
    required UserRole role,
  }) : this(status: AuthStatus.authenticated, userId: userId, role: role);

  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);

  const AuthState.authenticating() : this(status: AuthStatus.authenticating);

  const AuthState.error(String message)
    : this(status: AuthStatus.error, errorMessage: message);

  bool get isAuthenticated => status == AuthStatus.authenticated;
}
