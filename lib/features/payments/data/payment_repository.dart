import '../../../core/networking/api_client_interface.dart';
import '../domain/models/payment_models.dart';

class PaymentRepository {
  final IApiClient _apiClient;
  final String _organizationId;

  PaymentRepository(this._apiClient, this._organizationId);

  String get _baseUrl => '/organizations/$_organizationId/payments';

  Future<PaymentOrder?> createOrder(String bookingId) async {
    final response = await _apiClient.post(
      '$_baseUrl/order',
      data: {'bookingId': bookingId},
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
  }) async {
    final response = await _apiClient.post(
      '$_baseUrl/verify',
      data: {
        'providerOrderId': providerOrderId,
        'providerPaymentId': providerPaymentId,
        'signature': signature,
      },
    );

    return response.isSuccess;
  }
}
