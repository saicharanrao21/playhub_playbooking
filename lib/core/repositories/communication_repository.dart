import '../networking/api_client_interface.dart';

enum CommunicationChannel { inApp, email, sms, whatsapp, push }

enum CommunicationCategory { transactional, marketing, security }

class CommunicationPreference {
  final CommunicationCategory category;
  final CommunicationChannel channel;
  final bool isEnabled;

  CommunicationPreference({
    required this.category,
    required this.channel,
    required this.isEnabled,
  });

  factory CommunicationPreference.fromJson(Map<String, dynamic> json) {
    return CommunicationPreference(
      category: _parseCategory(json['category']),
      channel: _parseChannel(json['channel']),
      isEnabled: json['isEnabled'],
    );
  }

  static CommunicationCategory _parseCategory(String value) {
    return CommunicationCategory.values.firstWhere(
      (e) => e.name.toUpperCase() == value,
      orElse: () => CommunicationCategory.transactional,
    );
  }

  static CommunicationChannel _parseChannel(String value) {
    return CommunicationChannel.values.firstWhere(
      (e) => e.name.toUpperCase() == value,
      orElse: () => CommunicationChannel.inApp,
    );
  }
}

class CommunicationRepository {
  final IApiClient _apiClient;

  CommunicationRepository(this._apiClient);

  Future<void> registerDevice(String token, String platform) async {
    await _apiClient.post(
      '/communication/devices',
      data: {
        'token': token,
        'platform': platform,
      },
    );
  }

  Future<void> unregisterDevice(String token) async {
    await _apiClient.delete('/communication/devices/$token');
  }

  Future<List<CommunicationPreference>> getPreferences() async {
    final response = await _apiClient.get<List<dynamic>>('/communication/preferences');
    if (response.isSuccess) {
      return response.data!.map((p) => CommunicationPreference.fromJson(p)).toList();
    }
    return [];
  }

  Future<void> updatePreference(
    CommunicationCategory category,
    CommunicationChannel channel,
    bool isEnabled,
  ) async {
    await _apiClient.patch(
      '/communication/preferences',
      data: {
        'category': category.name.toUpperCase(),
        'channel': channel.name.toUpperCase(),
        'isEnabled': isEnabled,
      },
    );
  }
}
