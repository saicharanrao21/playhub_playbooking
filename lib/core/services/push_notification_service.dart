import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/repository_providers.dart';
import '../storage/storage_interface.dart';
import '../../app/bootstrap/bootstrap.dart';

abstract class IPushNotificationService {
  Future<void> initialize();
  Future<String?> getToken();
  Future<void> subscribeToTopic(String topic);
  Future<void> unsubscribeFromTopic(String topic);
}

class MockPushNotificationService implements IPushNotificationService {
  final IStorage _storage;
  static const _tokenKey = 'mock_push_token';

  MockPushNotificationService(this._storage);

  @override
  Future<void> initialize() async {
    debugPrint('MockPushNotificationService: Initializing...');
  }

  @override
  Future<String?> getToken() async {
    String? token = await _storage.read(_tokenKey);
    if (token == null) {
      token = 'mock-token-${DateTime.now().millisecondsSinceEpoch}';
      await _storage.write(_tokenKey, token);
    }
    return token;
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
  final storage = ref.watch(localStorageProvider);
  return MockPushNotificationService(storage);
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
