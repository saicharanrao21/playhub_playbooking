import '../models/auth_models.dart';

/// Interface for Authentication.
abstract class IAuthRepository {
  /// Initializes the auth state by restoring session from storage.
  Future<void> initialize();

  /// Performs login and returns the identity if successful.
  Future<UserIdentity?> login(String email, String password);

  /// Performs logout and clears local session.
  Future<void> logout();

  /// Refreshes the current session using a refresh token.
  Future<UserIdentity?> refreshSession();

  /// Returns the current user identity if authenticated.
  UserIdentity? getCurrentIdentity();

  /// Stream of user identity changes.
  Stream<UserIdentity?> get identityChanges;

  // Design for future expansion (Not implemented in this phase)
  // Future<void> register(String name, String email, String password);
  // Future<void> verifyOtp(String code);
  // Future<void> requestPasswordReset(String email);
}
