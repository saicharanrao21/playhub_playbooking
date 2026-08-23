import '../../../core/networking/api_client_interface.dart';

class DashboardStats {
  final int venuesCount;
  final int facilitiesCount;
  final int todayBookings;
  final int upcomingBookings;

  DashboardStats({
    required this.venuesCount,
    required this.facilitiesCount,
    required this.todayBookings,
    required this.upcomingBookings,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      venuesCount: json['venuesCount'] ?? 0,
      facilitiesCount: json['facilitiesCount'] ?? 0,
      todayBookings: json['todayBookings'] ?? 0,
      upcomingBookings: json['upcomingBookings'] ?? 0,
    );
  }
}

class DashboardRepository {
  final IApiClient _apiClient;

  DashboardRepository(this._apiClient);

  Future<DashboardStats?> getStats() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/organizations/dashboard/stats');
    if (response.isSuccess) {
      return DashboardStats.fromJson(response.data!);
    }
    return null;
  }
}
