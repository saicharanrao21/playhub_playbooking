import 'dart:async';
import '../models/auth_models.dart';
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
      try {
        final identity = await _fetchProfile(token);
        if (identity != null) {
          _currentIdentity = identity;
          _identityController.add(_currentIdentity);
          AppLogger.info('Session restored and profile fetched.');
        } else {
          await handleSessionExpired();
        }
      } catch (e) {
        AppLogger.error('Failed to restore session profile', e);
        _identityController.add(null);
      }
    } else {
      AppLogger.info('No existing session found.');
      _identityController.add(null);
    }
  }

  @override
  Future<UserIdentity?> login(String email, String password) async {
    AppLogger.info('Attempting login for: $email');

    try {
      final response = await _apiClient.post(
        '/auth/login',
        data: {'email': email, 'password': password},
        authenticated: false,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final access = data['accessToken']?.toString() ?? '';
        final refresh = data['refreshToken']?.toString() ?? '';

        await _tokenStorage.saveAccessToken(access);
        await _tokenStorage.saveRefreshToken(refresh);

        final identity = await _fetchProfile(access);
        if (identity != null) {
          await _saveSession(access, refresh, identity);
          return identity;
        }
      }
    } catch (e) {
      AppLogger.error('Login request failed', e);
    }

    AppLogger.warning('Login failed for: $email');
    return null;
  }

  @override
  Future<UserIdentity?> refreshSession() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) {
      await handleSessionExpired();
      return null;
    }

    try {
      final response = await _apiClient.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        authenticated: false,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final access = data['accessToken']?.toString() ?? '';
        final newRefresh = data['refreshToken']?.toString() ?? '';

        await _tokenStorage.saveAccessToken(access);
        await _tokenStorage.saveRefreshToken(newRefresh);

        final identity = await _fetchProfile(access);
        if (identity != null) {
          await _saveSession(access, newRefresh, identity);
          return identity;
        }
      }
    } catch (e) {
      AppLogger.error('Session refresh failed', e);
    }

    await handleSessionExpired();
    return null;
  }

  Future<UserIdentity?> _fetchProfile([String? explicitToken]) async {
    try {
      final token = explicitToken ?? await _tokenStorage.readAccessToken();
      final headers = token != null ? {'Authorization': 'Bearer $token'} : null;
      final response = await _apiClient.get(
        '/auth/me',
        headers: headers,
      );
      if (response.isSuccess && response.data != null) {
        return UserIdentity.fromJson(Map<String, dynamic>.from(response.data as Map));
      }
    } catch (e) {
      AppLogger.error('Failed to fetch profile', e);
    }
    return null;
  }

  @override
  Future<UserIdentity?> register(
    String email,
    String password,
    String fullName,
  ) async {
    AppLogger.info('Attempting registration for: $email');

    try {
      final response = await _apiClient.post(
        '/auth/register',
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
        },
        authenticated: false,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final access = data['accessToken']?.toString() ?? '';
        final refresh = data['refreshToken']?.toString() ?? '';

        await _tokenStorage.saveAccessToken(access);
        await _tokenStorage.saveRefreshToken(refresh);

        final identity = await _fetchProfile(access);
        if (identity != null) {
          await _saveSession(access, refresh, identity);
          return identity;
        }
      }
    } catch (e) {
      AppLogger.error('Registration request failed', e);
    }

    AppLogger.warning('Registration failed for: $email');
    return null;
  }

  @override
  Future<void> logout() async {
    AppLogger.info('Logging out user...');
    try {
      await _apiClient.post('/auth/logout');
    } catch (e) {
      AppLogger.warning('Backend logout failed: $e');
    }
    await handleSessionExpired();
  }

  @override
  UserIdentity? getCurrentIdentity() => _currentIdentity;

  @override
  Stream<UserIdentity?> get identityChanges => _identityController.stream;

  @override
  Future<void> handleSessionExpired() async {
    AppLogger.info('Handling session expiration...');
    await _tokenStorage.clearTokens();
    _currentIdentity = null;
    _identityController.add(null);
  }

  Future<void> _saveSession(
    String access,
    String refresh,
    UserIdentity identity,
  ) async {
    await _tokenStorage.saveAccessToken(access);
    await _tokenStorage.saveRefreshToken(refresh);
    _currentIdentity = identity;
    _identityController.add(_currentIdentity);
    AppLogger.info('Session saved for user: ${identity.email}');
  }
}
