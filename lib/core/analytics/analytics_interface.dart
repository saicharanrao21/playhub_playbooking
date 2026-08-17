/// Interface for Analytics.
///
/// Real implementation (e.g., Firebase Analytics) will be added later.
abstract class IAnalytics {
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters});
  Future<void> setCurrentScreen(String screenName);
  Future<void> setUserId(String? id);
  Future<void> setUserProperty(String name, String value);
}

class NoopAnalytics implements IAnalytics {
  @override
  Future<void> logEvent(
    String name, {
    Map<String, dynamic>? parameters,
  }) async {}

  @override
  Future<void> setCurrentScreen(String screenName) async {}

  @override
  Future<void> setUserId(String? id) async {}

  @override
  Future<void> setUserProperty(String name, String value) async {}
}
