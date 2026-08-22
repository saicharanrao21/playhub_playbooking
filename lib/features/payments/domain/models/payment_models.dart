enum PaymentStatus { initiated, pending, authorized, captured, failed, cancelled, refunded }
enum PaymentProvider { razorpay, stripe, mock }

class PaymentOrder {
  final String id;
  final String bookingId;
  final double amount;
  final String currency;
  final PaymentStatus status;
  final String providerOrderId;
  final PaymentProvider provider;

  const PaymentOrder({
    required this.id,
    required this.bookingId,
    required this.amount,
    required this.currency,
    required this.status,
    required this.providerOrderId,
    required this.provider,
  });

  factory PaymentOrder.fromJson(Map<String, dynamic> json) {
    return PaymentOrder(
      id: json['id'],
      bookingId: json['bookingId'],
      amount: double.parse(json['amount'].toString()),
      currency: json['currency'],
      status: PaymentStatus.values.byName(json['status'].toString().toLowerCase()),
      providerOrderId: json['providerOrderId'],
      provider: PaymentProvider.values.byName(json['provider'].toString().toLowerCase()),
    );
  }
}
