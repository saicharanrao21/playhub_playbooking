import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/repository_providers.dart';

abstract class IPushNotificationService {
  Future<void> initialize();
  Future<String?> getToken();
  Future<void> subscribeToTopic(String topic);
  Future<void> unsubscribeFromTopic(String topic);
}

class MockPushNotificationService implements IPushNotificationService {
  @override
  Future<void> initialize() async {
    debugPrint('MockPushNotificationService: Initializing...');
  }

  @override
  Future<String?> getToken() async {
    return 'mock-token-${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<void> subscribeToTopic(String topic) async {
    debugPrint('MockPushNotificationService: Subscribed to $topic');
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) async {
    debugPrint('MockPushNotificationService: Unsubscribed from $topic');
  }
}

final pushNotificationServiceProvider = Provider<IPushNotificationService>((ref) {
  return MockPushNotificationService();
});

// Helper provider to handle device registration on login
final deviceRegistrationProvider = Provider<DeviceRegistrationManager>((ref) {
  return DeviceRegistrationManager(ref);
});

class DeviceRegistrationManager {
  final Ref _ref;

  DeviceRegistrationManager(this._ref);

  Future<void> registerCurrentDevice() async {
    try {
      final pushService = _ref.read(pushNotificationServiceProvider);
      final repo = _ref.read(communicationRepositoryProvider);
      
      final token = await pushService.getToken();
      if (token != null) {
        final platform = kIsWeb ? 'web' : (Platform.isIOS ? 'ios' : 'android');
        await repo.registerDevice(token, platform);
        debugPrint('Device registered successfully with token: $token');
      }
    } catch (e) {
      debugPrint('Failed to register device: $e');
    }
  }
}
