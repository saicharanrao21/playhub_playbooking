import 'dart:async';
import '../models/auth_models.dart';
import '../models/app_models.dart';
import '../networking/api_client_interface.dart';
import 'auth_interface.dart';
import 'token_storage.dart';
import '../logging/app_logger.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final IApiClient _apiClient;
  final TokenStorage _tokenStorage;

  final _identityController = StreamController<UserIdentity?>.broadcast();
  UserIdentity? _currentIdentity;

  AuthRepositoryImpl(this._apiClient, this._tokenStorage);

  @override
  Future<void> initialize() async {
    AppLogger.info('Initializing AuthRepository...');
    final token = await _tokenStorage.readAccessToken();
    if (token != null) {
      // In a real app, we might validate the token or fetch user profile
      // For now, we'll assume valid if token exists in dummy mode
      _apiClient.setToken(token);

      // Mock restoring identity
      _currentIdentity = const UserIdentity(
        id: 'u1',
        email: 'john@example.com',
        name: 'John Doe',
        role: UserRole.customer,
      );
      _identityController.add(_currentIdentity);
      AppLogger.info('Session restored for: ${_currentIdentity?.email}');
    } else {
      AppLogger.info('No existing session found.');
      _identityController.add(null);
    }
  }

  @override
  Future<UserIdentity?> login(String email, String password) async {
    AppLogger.info('Attempting login for: $email');

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (email == 'admin@playhub.com' && password == 'password') {
      final identity = UserIdentity(
        id: 'admin_1',
        email: email,
        name: 'Admin User',
        role: UserRole.admin,
      );

      await _saveSession('mock_access_token', 'mock_refresh_token', identity);
      return identity;
    } else if (email == 'user@playhub.com' && password == 'password') {
      final identity = UserIdentity(
        id: 'user_1',
        email: email,
        name: 'Regular User',
        role: UserRole.customer,
      );

      await _saveSession('mock_access_token', 'mock_refresh_token', identity);
      return identity;
    }

    AppLogger.warning('Login failed for: $email');
    return null;
  }

  @override
  Future<void> logout() async {
    AppLogger.info('Logging out...');
    await _tokenStorage.clearTokens();
    _apiClient.setToken(null);
    _currentIdentity = null;
    _identityController.add(null);
  }

  @override
  Future<UserIdentity?> refreshSession() async {
    AppLogger.info('Refreshing session...');
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) return null;

    // Simulate token refresh API call
    await Future.delayed(const Duration(milliseconds: 500));

    // In a real app, update tokens and identity
    return _currentIdentity;
  }

  @override
  UserIdentity? getCurrentIdentity() => _currentIdentity;

  @override
  Stream<UserIdentity?> get identityChanges => _identityController.stream;

  Future<void> _saveSession(
    String access,
    String refresh,
    UserIdentity identity,
  ) async {
    await _tokenStorage.saveAccessToken(access);
    await _tokenStorage.saveRefreshToken(refresh);
    _apiClient.setToken(access);
    _currentIdentity = identity;
    _identityController.add(_currentIdentity);
  }
}
