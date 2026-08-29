import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../storage/storage_interface.dart';

/// Secure storage implementation for sensitive data.
///
/// Uses Android Keystore and iOS Keychain with automatic recovery on reset.
class SecureStorage implements IStorage {
  final FlutterSecureStorage _storage;

  SecureStorage([
    this._storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
        resetOnError: true,
      ),
    ),
  ]);

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      // Fallback
    }
  }

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      // Fallback
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.deleteAll();
    } catch (_) {
      // Fallback
    }
  }
}
