/// Base exception for PlayHub application.
abstract class AppException implements Exception {
  final String message;
  final String? code;

  AppException(this.message, [this.code]);

  @override
  String toString() => 'AppException: [$code] $message';
}

class NetworkException extends AppException {
  NetworkException([String message = 'Network connection error'])
    : super(message, 'network_error');
}

class ServerException extends AppException {
  ServerException([String message = 'Server error occurred'])
    : super(message, 'server_error');
}

class AuthenticationException extends AppException {
  AuthenticationException([String message = 'Authentication failed'])
    : super(message, 'auth_error');
}

class AuthorizationException extends AppException {
  AuthorizationException([String message = 'Permission denied'])
    : super(message, 'permission_denied');
}

class ValidationException extends AppException {
  ValidationException(String message) : super(message, 'validation_error');
}

class CacheException extends AppException {
  CacheException([String message = 'Local storage error'])
    : super(message, 'cache_error');
}

class UnknownException extends AppException {
  UnknownException([String message = 'An unexpected error occurred'])
    : super(message, 'unknown_error');
}
