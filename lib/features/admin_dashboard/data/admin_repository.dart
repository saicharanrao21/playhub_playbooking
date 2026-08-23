import '../../../core/networking/api_client_interface.dart';

class AdminStats {
  final int totalUsers;
  final int totalVenues;
  final int activeBookings;
  final List<dynamic> pendingBusinesses;

  AdminStats({
    required this.totalUsers,
    required this.totalVenues,
    required this.activeBookings,
    required this.pendingBusinesses,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['totalUsers'] ?? 0,
      totalVenues: json['totalVenues'] ?? 0,
      activeBookings: json['activeBookings'] ?? 0,
      pendingBusinesses: json['pendingBusinesses'] ?? [],
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

  Future<bool> approveBusiness(String id) async {
    final response = await _apiClient.post('/admin/businesses/$id/approve');
    return response.isSuccess;
  }
}
