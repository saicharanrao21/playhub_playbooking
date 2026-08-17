import 'package:logger/logger.dart';

/// Centralized logging abstraction for PlayHub.
///
/// This class ensures consistent logging levels and formatting across the app.
/// It also provides a place to implement redaction for sensitive data.
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
    ),
  );

  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void info(String message) {
    _logger.i(message);
  }

  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Logs a sensitive message with redaction.
  ///
  /// In a real implementation, this would scan [data] for keys like 'password'
  /// or 'token' and replace their values with '[REDACTED]'.
  static void logSensitive(String message, Map<String, dynamic> data) {
    final redactedData = _redact(data);
    _logger.i('$message: $redactedData');
  }

  static Map<String, dynamic> _redact(Map<String, dynamic> data) {
    final Map<String, dynamic> redacted = Map.from(data);
    const sensitiveKeys = {
      'password',
      'otp',
      'token',
      'access_token',
      'refresh_token',
      'secret',
      'cvv',
      'card_number',
    };

    redacted.forEach((key, value) {
      if (sensitiveKeys.contains(key.toLowerCase())) {
        redacted[key] = '[REDACTED]';
      } else if (value is Map<String, dynamic>) {
        redacted[key] = _redact(value);
      }
    });

    return redacted;
  }
}
