import 'package:shared_preferences/shared_preferences.dart';
import 'storage_interface.dart';

class LocalStorage implements IStorage {
  final SharedPreferences _prefs;

  LocalStorage(this._prefs);

  @override
  Future<void> write(String key, String value) async {
    await _prefs.setString(key, value);
  }

  @override
  Future<String?> read(String key) async {
    return _prefs.getString(key);
  }

  @override
  Future<void> delete(String key) async {
    await _prefs.remove(key);
  }

  @override
  Future<void> clear() async {
    await _prefs.clear();
  }

  // Helper for booleans
  Future<void> writeBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  bool? readBool(String key) {
    return _prefs.getBool(key);
  }
}
