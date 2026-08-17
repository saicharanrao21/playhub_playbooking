import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../core/config/app_config.dart';
import '../../core/config/env_config.dart';
import '../../core/logging/app_logger.dart';
import '../../core/storage/local_storage.dart';
import '../../core/networking/dio_api_client.dart';
import '../../core/networking/api_client_interface.dart';
import '../../core/security/secure_storage.dart';

/// Provider for LocalStorage.
final localStorageProvider = Provider<LocalStorage>((ref) {
  throw UnimplementedError(
    'localStorageProvider must be overridden in ProviderScope',
  );
});

/// Provider for SecureStorage.
final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

/// Provider for API Client.
final apiClientProvider = Provider<IApiClient>((ref) {
  final config = ref.watch(appConfigProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  return DioApiClient(dio);
});

/// Handles application initialization logic.
class Bootstrap {
  static Future<ProviderContainer> createContainer({EnvConfig? config}) async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Initialize Configuration
    AppConfig.initialize(config ?? EnvConfig.dev());
    AppLogger.info(
      'Initializing PlayHub in ${AppConfig.current.environment.name} environment',
    );

    // 2. Initialize Core Services
    final prefs = await SharedPreferences.getInstance();
    final localStorage = LocalStorage(prefs);

    // 3. Create ProviderContainer with overrides
    final container = ProviderContainer(
      overrides: [localStorageProvider.overrideWithValue(localStorage)],
    );

    return container;
  }
}
