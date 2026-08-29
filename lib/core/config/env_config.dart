enum AppEnvironment { local, dev, staging, prod }

/// Holds environment-specific configuration values.
class EnvConfig {
  final AppEnvironment environment;
  final String apiBaseUrl;
  final bool enableLogging;
  final bool enableAnalytics;

  const EnvConfig({
    required this.environment,
    required this.apiBaseUrl,
    this.enableLogging = true,
    this.enableAnalytics = false,
  });

  factory EnvConfig.local() => const EnvConfig(
    environment: AppEnvironment.local,
    apiBaseUrl: 'http://localhost:3000/api/v1',
    enableLogging: true,
  );

  factory EnvConfig.dev() => const EnvConfig(
    environment: AppEnvironment.dev,
    apiBaseUrl: 'https://dev-api.playhub.com/api/v1',
    enableLogging: true,
  );

  factory EnvConfig.staging() => const EnvConfig(
    environment: AppEnvironment.staging,
    apiBaseUrl: 'https://playhub-backend-staging.onrender.com/api/v1',
    enableLogging: true,
    enableAnalytics: true,
  );

  factory EnvConfig.prod() => const EnvConfig(
    environment: AppEnvironment.prod,
    apiBaseUrl: 'https://api.playhub.com/api/v1',
    enableLogging: false,
    enableAnalytics: true,
  );

  factory EnvConfig.fromEnvironment() {
    const env = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

    late EnvConfig config;
    switch (env) {
      case 'local':
        config = EnvConfig.local();
        break;
      case 'staging':
        config = EnvConfig.staging();
        break;
      case 'prod':
        config = EnvConfig.prod();
        break;
      default:
        config = EnvConfig.dev();
    }

    return config.copyWith(
      apiBaseUrl: apiBaseUrl.isNotEmpty ? apiBaseUrl : null,
    );
  }

  EnvConfig copyWith({
    AppEnvironment? environment,
    String? apiBaseUrl,
    bool? enableLogging,
    bool? enableAnalytics,
  }) {
    return EnvConfig(
      environment: environment ?? this.environment,
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      enableLogging: enableLogging ?? this.enableLogging,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
    );
  }
}
