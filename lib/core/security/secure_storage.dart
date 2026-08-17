import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../storage/storage_interface.dart';

/// Secure storage implementation for sensitive data.
///
/// Uses Android Keystore and iOS Keychain.
class SecureStorage implements IStorage {
  final FlutterSecureStorage _storage;

  SecureStorage([this._storage = const FlutterSecureStorage()]);

  @override
  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read(String key) async {
    return await _storage.read(key: key);
  }

  @override
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  @override
  Future<void> clear() async {
    await _storage.deleteAll();
  }
}
