class TimeInterval {
  final DateTime start;
  final DateTime end;

  const TimeInterval({required this.start, required this.end});

  factory TimeInterval.fromJson(Map<String, dynamic> json) {
    return TimeInterval(
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
    );
  }
}

class Availability {
  final String facilityId;
  final String date;
  final String timezone;
  final List<TimeInterval> availableIntervals;
  final List<TimeInterval> slots;

  const Availability({
    required this.facilityId,
    required this.date,
    required this.timezone,
    required this.availableIntervals,
    required this.slots,
  });

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      facilityId: json['facilityId'],
      date: json['date'],
      timezone: json['timezone'],
      availableIntervals: (json['availableIntervals'] as List)
          .map((i) => TimeInterval.fromJson(i))
          .toList(),
      slots: (json['slots'] as List)
          .map((s) => TimeInterval.fromJson(s))
          .toList(),
    );
  }
}
