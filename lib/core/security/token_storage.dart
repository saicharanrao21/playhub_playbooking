import '../storage/storage_interface.dart';

/// Abstraction for secure token storage.
class TokenStorage {
  final IStorage _storage;

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';

  TokenStorage(this._storage);

  Future<void> saveAccessToken(String token) async {
    await _storage.write(_keyAccessToken, token);
  }

  Future<String?> readAccessToken() async {
    return await _storage.read(_keyAccessToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(_keyRefreshToken, token);
  }

  Future<String?> readRefreshToken() async {
    return await _storage.read(_keyRefreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(_keyAccessToken);
    await _storage.delete(_keyRefreshToken);
  }
}
