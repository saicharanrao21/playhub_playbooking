import 'dart:async';

/// Global bus for authentication-related events.
class AuthEvents {
  static final _sessionExpiredController = StreamController<void>.broadcast();

  static Stream<void> get sessionExpired => _sessionExpiredController.stream;

  static void notifySessionExpired() {
    _sessionExpiredController.add(null);
  }
}
