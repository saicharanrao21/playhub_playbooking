import '../models/app_models.dart';

/// Interface for Authentication.
///
/// Real implementation will be added in later phases.
abstract class IAuthRepository {
  Future<User?> login(String email, String password);
  Future<User?> register(String name, String email, String password);
  Future<void> logout();
  Future<User?> getCurrentUser();
  Stream<User?> get userChanges;
}
