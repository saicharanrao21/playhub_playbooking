import 'dart:async';
import '../models/auth_models.dart';
import '../models/app_models.dart';
import '../networking/api_client_interface.dart';
import 'auth_interface.dart';
import 'token_storage.dart';
import 'auth_events.dart';
import '../logging/app_logger.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final IApiClient _apiClient;
  final TokenStorage _tokenStorage;

  final _identityController = StreamController<UserIdentity?>.broadcast();
  UserIdentity? _currentIdentity;

  AuthRepositoryImpl(this._apiClient, this._tokenStorage) {
    AuthEvents.sessionExpired.listen((_) => handleSessionExpired());
  }

  @override
  Future<void> initialize() async {
    AppLogger.info('Initializing AuthRepository...');
    final token = await _tokenStorage.readAccessToken();
    if (token != null) {
      // For now, we assume token validity or let the first request trigger refresh
      // In a real app, we'd fetch the user profile here
      _currentIdentity = const UserIdentity(
        id: 'restored',
        email: 'restored@example.com',
        name: 'Restored User',
        role: UserRole.customer,
      );
      _identityController.add(_currentIdentity);
      AppLogger.info('Session found in local storage.');
    } else {
      AppLogger.info('No existing session found.');
      _identityController.add(null);
    }
  }

  @override
  Future<UserIdentity?> login(String email, String password) async {
    AppLogger.info('Attempting login for: $email');

    final response = await _apiClient.post(
      '/auth/login',
      data: {'email': email, 'password': password},
      authenticated: false,
    );

    if (response.isSuccess) {
      final data = response.data as Map<String, dynamic>;
      final access = data['accessToken'];
      final refresh = data['refreshToken'];

      // In a real app, we would parse UserIdentity from the response
      // For this phase, we'll create a dummy identity based on login success
      final identity = UserIdentity(
        id: 'u1',
        email: email,
        name: email.split('@')[0],
        role: email.contains('admin') ? UserRole.admin : UserRole.customer,
      );

      await _saveSession(access, refresh, identity);
      return identity;
    }

    AppLogger.warning('Login failed for: $email');
    return null;
  }

  @override
  Future<UserIdentity?> register(
    String email,
    String password,
    String fullName,
  ) async {
    AppLogger.info('Attempting registration for: $email');

    final response = await _apiClient.post(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'fullName': fullName,
      },
      authenticated: false,
    );

    if (response.isSuccess) {
      final data = response.data as Map<String, dynamic>;
      final access = data['accessToken'];
      final refresh = data['refreshToken'];

      final identity = UserIdentity(
        id: 'u_new',
        email: email,
        name: fullName,
        role: UserRole.customer,
      );

      await _saveSession(access, refresh, identity);
      return identity;
    }

    AppLogger.warning('Registration failed for: $email');
    return null;
  }

  @override
  Future<void> logout() async {
    AppLogger.info('Logging out...');
    try {
      await _apiClient.post('/auth/logout');
    } catch (e) {
      AppLogger.error('Server-side logout failed', e);
    }

    await _tokenStorage.clearTokens();
    _currentIdentity = null;
    _identityController.add(null);
  }

  @override
  Future<UserIdentity?> refreshSession() async {
    AppLogger.info('Refreshing session manually...');
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) return null;

    final response = await _apiClient.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
      authenticated: false,
    );

    if (response.isSuccess) {
      final data = response.data as Map<String, dynamic>;
      final access = data['accessToken'];
      final refresh = data['refreshToken'];

      if (_currentIdentity != null) {
        await _saveSession(access, refresh, _currentIdentity!);
      }
      return _currentIdentity;
    }
    return null;
  }

  @override
  UserIdentity? getCurrentIdentity() => _currentIdentity;

  @override
  Future<void> handleSessionExpired() async {
    AppLogger.warning('Session expired or compromised. Clearing local state.');
    await _tokenStorage.clearTokens();
    _currentIdentity = null;
    _identityController.add(null);
  }

  @override
  Stream<UserIdentity?> get identityChanges => _identityController.stream;

  Future<void> _saveSession(
    String access,
    String refresh,
    UserIdentity identity,
  ) async {
    await _tokenStorage.saveAccessToken(access);
    await _tokenStorage.saveRefreshToken(refresh);
    _currentIdentity = identity;
    _identityController.add(_currentIdentity);
  }
}
