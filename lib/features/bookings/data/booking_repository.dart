import '../../../core/networking/api_client_interface.dart';
import '../domain/models/booking_models.dart';

class BookingRepository {
  final IApiClient _apiClient;
  final String _organizationId;

  BookingRepository(this._apiClient, this._organizationId);

  String get _baseUrl => '/organizations/$_organizationId/bookings';

  Future<Booking?> createBooking({
    required String facilityId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final response = await _apiClient.post(
      '$_baseUrl/$facilityId',
      data: {
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
      },
    );

    if (response.isSuccess) {
      return Booking.fromJson(response.data);
    }
    return null;
  }

  Future<List<Booking>> getMyBookings() async {
    final response = await _apiClient.get<Map<String, dynamic>>(_baseUrl);
    if (response.isSuccess) {
      final items = response.data!['items'] as List;
      return items.map((b) => Booking.fromJson(b)).toList();
    }
    return [];
  }

  Future<Booking?> getBooking(String id) async {
    final response = await _apiClient.get('$_baseUrl/$id');
    if (response.isSuccess) {
      return Booking.fromJson(response.data);
    }
    return null;
  }

  Future<void> cancelBooking(String id, {String? reason}) async {
    await _apiClient.patch(
      '$_baseUrl/$id/cancel',
      data: {'reason': reason},
    );
  }

  Future<Booking?> rescheduleBooking({
    required String bookingId,
    required DateTime newStartTime,
    required DateTime newEndTime,
  }) async {
    final response = await _apiClient.patch(
      '$_baseUrl/$bookingId/reschedule',
      data: {
        'newStartTime': newStartTime.toIso8601String(),
        'newEndTime': newEndTime.toIso8601String(),
      },
    );

    if (response.isSuccess) {
      return Booking.fromJson(response.data);
    }
    return null;
  }

  Future<String?> getQrPass(String bookingId) async {
    final response = await _apiClient.get<Map<String, dynamic>>('$_baseUrl/$bookingId/qr-pass');
    if (response.isSuccess && response.data != null) {
      return response.data!['qrToken']?.toString();
    }
    return null;
  }
}
