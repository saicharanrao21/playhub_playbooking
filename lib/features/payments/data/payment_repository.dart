import '../../../core/networking/api_client_interface.dart';
import '../domain/models/payment_models.dart';

class PaymentRepository {
  final IApiClient _apiClient;
  final String _organizationId;

  PaymentRepository(this._apiClient, this._organizationId);

  String get _baseUrl => '/organizations/$_organizationId/payments';

  Future<PaymentOrder?> createOrder(String bookingId, {PaymentProvider? provider}) async {
    final response = await _apiClient.post(
      '$_baseUrl/order',
      data: {
        'bookingId': bookingId,
        'provider': provider?.name.toUpperCase(),
      },
    );

    if (response.isSuccess) {
      return PaymentOrder.fromJson(response.data);
    }
    return null;
  }

  Future<bool> verifyPayment({
    required String providerOrderId,
    required String providerPaymentId,
    required String signature,
    Map<String, dynamic>? metadata,
  }) async {
    final response = await _apiClient.post(
      '$_baseUrl/verify',
      data: {
        'providerOrderId': providerOrderId,
        'providerPaymentId': providerPaymentId,
        'signature': signature,
        'metadata': metadata,
      },
    );

    return response.isSuccess;
  }

  Future<bool> initiateRefund(String paymentId, {String? reason}) async {
    final response = await _apiClient.post(
      '$_baseUrl/$paymentId/refund',
      data: {'reason': reason},
    );
    return response.isSuccess;
  }
}
