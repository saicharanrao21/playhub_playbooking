enum BookingStatus {
  pending,
  confirmed,
  cancelled,
  rejected,
  checkedIn,
  noShow,
  completed
}

extension BookingStatusX on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.pending: return 'Pending';
      case BookingStatus.confirmed: return 'Confirmed';
      case BookingStatus.cancelled: return 'Cancelled';
      case BookingStatus.rejected: return 'Rejected';
      case BookingStatus.checkedIn: return 'Checked In';
      case BookingStatus.noShow: return 'No Show';
      case BookingStatus.completed: return 'Completed';
    }
  }
}

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
    final statusStr = json['status']?.toString().toLowerCase().replaceAll('_', '') ?? 'pending';
    return Booking(
      id: json['id'],
      organizationId: json['organizationId'],
      facilityId: json['facilityId'],
      userId: json['userId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      status: BookingStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == statusStr,
        orElse: () => BookingStatus.pending,
      ),
      totalPrice: json['totalPrice'] != null ? double.tryParse(json['totalPrice'].toString()) : null,
      currency: json['currency'],
    );
  }
}
