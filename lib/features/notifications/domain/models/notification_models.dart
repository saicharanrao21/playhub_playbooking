enum NotificationType {
  bookingCreated,
  bookingConfirmed,
  bookingCancelled,
  paymentSuccess,
  paymentFailed,
  systemAlert
}

class AppNotification {
  final String id;
  final String organizationId;
  final String userId;
  final String? bookingId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.organizationId,
    required this.userId,
    this.bookingId,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      organizationId: json['organizationId'],
      userId: json['userId'],
      bookingId: json['bookingId'],
      type: _parseType(json['type']),
      title: json['title'],
      message: json['message'],
      data: json['data'],
      isRead: json['isRead'],
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  static NotificationType _parseType(String type) {
    switch (type.toUpperCase()) {
      case 'BOOKING_CREATED':
        return NotificationType.bookingCreated;
      case 'BOOKING_CONFIRMED':
        return NotificationType.bookingConfirmed;
      case 'BOOKING_CANCELLED':
        return NotificationType.bookingCancelled;
      case 'PAYMENT_SUCCESS':
        return NotificationType.paymentSuccess;
      case 'PAYMENT_FAILED':
        return NotificationType.paymentFailed;
      default:
        return NotificationType.systemAlert;
    }
  }
}
