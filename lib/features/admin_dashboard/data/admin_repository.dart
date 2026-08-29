import '../../../core/networking/api_client_interface.dart';
import 'admin_models.dart';

class AdminStats {
  final int totalUsers;
  final int totalVenues;
  final int activeBookings;
  final int pendingBusinesses;
  final int pendingKYC;

  AdminStats({
    required this.totalUsers,
    required this.totalVenues,
    required this.activeBookings,
    required this.pendingBusinesses,
    required this.pendingKYC,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['totalUsers'] ?? 0,
      totalVenues: json['totalVenues'] ?? 0,
      activeBookings: json['activeBookings'] ?? 0,
      pendingBusinesses: json['pendingBusinesses'] ?? 0,
      pendingKYC: json['pendingKYC'] ?? 0,
    );
  }
}

class AdminRepository {
  final IApiClient _apiClient;

  AdminRepository(this._apiClient);

  Future<AdminStats?> getStats() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/admin/dashboard/stats');
    if (response.isSuccess) {
      return AdminStats.fromJson(response.data!);
    }
    return null;
  }

  Future<List<AdminPartner>> getPartners({String? kycStatus, int limit = 20, int offset = 0}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/admin/partners',
      queryParameters: {
        'kycStatus': kycStatus,
        'limit': limit,
        'offset': offset,
      },
    );
    if (response.isSuccess) {
      final items = response.data!['items'] as List? ?? [];
      return items.map((i) => AdminPartner.fromJson(i as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<Map<String, dynamic>?> getPartnerDetails(String id) async {
    final response = await _apiClient.get<Map<String, dynamic>>('/admin/partners/$id');
    return response.isSuccess ? response.data : null;
  }

  Future<bool> reviewPartner(String id, String kycStatus, {String? reason}) async {
    final response = await _apiClient.post(
      '/admin/partners/$id/review',
      data: {'kycStatus': kycStatus, 'reason': reason},
    );
    return response.isSuccess;
  }

  Future<List<AdminAuditLog>> getAuditLogs({int limit = 50, int offset = 0}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      '/admin/audit-logs',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    if (response.isSuccess) {
      final items = response.data!['items'] as List? ?? [];
      return items.map((i) => AdminAuditLog.fromJson(i as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<bool> approveBusiness(String id) async {
    final response = await _apiClient.post('/admin/businesses/$id/approve');
    return response.isSuccess;
  }
}
