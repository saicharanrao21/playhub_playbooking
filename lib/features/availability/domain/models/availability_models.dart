class AvailableSlot {
  final DateTime startTime;
  final DateTime endTime;
  final double price;
  final String currency;
  final List<dynamic>? breakdown;

  const AvailableSlot({
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.currency,
    this.breakdown,
  });

  factory AvailableSlot.fromJson(Map<String, dynamic> json) {
    return AvailableSlot(
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] ?? 'INR',
      breakdown: json['breakdown'],
    );
  }
}

class Availability {
  final String facilityId;
  final String date;
  final String timezone;
  final int durationMinutes;
  final List<AvailableSlot> slots;

  const Availability({
    required this.facilityId,
    required this.date,
    required this.timezone,
    required this.durationMinutes,
    required this.slots,
  });

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      facilityId: json['facilityId'],
      date: json['date'],
      timezone: json['timezone'] ?? 'UTC',
      durationMinutes: json['durationMinutes'] ?? 60,
      slots: (json['slots'] as List? ?? [])
          .map((s) => AvailableSlot.fromJson(s))
          .toList(),
    );
  }
}

class AvailabilityQuery {
  final String facilityId;
  final String date;
  final int? durationMinutes;

  const AvailabilityQuery({
    required this.facilityId,
    required this.date,
    this.durationMinutes,
  });
}
