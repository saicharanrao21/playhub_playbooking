import '../models/auth_models.dart';

enum AuthStatus {
  initializing,
  authenticated,
  unauthenticated,
  authenticating,
  refreshing,
  sessionExpired,
  error,
}

class AuthState {
  final AuthStatus status;
  final UserIdentity? identity;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initializing,
    this.identity,
    this.errorMessage,
  });

  const AuthState.initializing() : this(status: AuthStatus.initializing);

  const AuthState.authenticated(UserIdentity identity)
    : this(status: AuthStatus.authenticated, identity: identity);

  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);

  const AuthState.authenticating() : this(status: AuthStatus.authenticating);

  const AuthState.refreshing() : this(status: AuthStatus.refreshing);

  const AuthState.sessionExpired() : this(status: AuthStatus.sessionExpired);

  const AuthState.error(String message)
    : this(status: AuthStatus.error, errorMessage: message);

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isInitializing => status == AuthStatus.initializing;
}
