enum BookingStatus { pending, confirmed, cancelled, completed }

class Booking {
  final String id;
  final String organizationId;
  final String facilityId;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final BookingStatus status;
  final double? totalPrice;
  final String? currency;

  const Booking({
    required this.id,
    required this.organizationId,
    required this.facilityId,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.totalPrice,
    this.currency,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      organizationId: json['organizationId'],
      facilityId: json['facilityId'],
      userId: json['userId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      status: BookingStatus.values.byName(json['status'].toString().toLowerCase()),
      totalPrice: json['totalPrice'] != null ? double.tryParse(json['totalPrice'].toString()) : null,
      currency: json['currency'],
    );
  }
}
