import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'env_config.dart';

/// Global application configuration manager.
class AppConfig {
  static late EnvConfig _current;

  static void initialize(EnvConfig config) {
    _current = config;
  }

  static EnvConfig get current => _current;

  static bool get isProduction => _current.environment == AppEnvironment.prod;
  static bool get isDevelopment =>
      _current.environment == AppEnvironment.dev ||
      _current.environment == AppEnvironment.local;
}

/// Provider for the application configuration.
final appConfigProvider = Provider<EnvConfig>((ref) {
  return AppConfig.current;
});
