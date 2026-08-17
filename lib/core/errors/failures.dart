/// Represents a failure in the domain layer.
///
/// Failures are returned from repositories/use cases instead of throwing exceptions.
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, [this.code]);

  @override
  String toString() => 'Failure: [$code] $message';
}

class NetworkFailure extends Failure {
  const NetworkFailure([
    String message = 'Please check your internet connection',
  ]) : super(message, 'network_failure');
}

class ServerFailure extends Failure {
  const ServerFailure([String message = 'Service is temporarily unavailable'])
    : super(message, 'server_failure');
}

class AuthFailure extends Failure {
  const AuthFailure([String message = 'Please login to continue'])
    : super(message, 'auth_failure');
}

class ValidationFailure extends Failure {
  const ValidationFailure(String message)
    : super(message, 'validation_failure');
}

class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'Something went wrong'])
    : super(message, 'unknown_failure');
}
