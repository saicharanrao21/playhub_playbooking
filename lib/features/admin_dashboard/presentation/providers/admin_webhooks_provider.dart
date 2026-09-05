import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/bootstrap/bootstrap.dart';

final adminWebhookLogsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, Map<String, String>>((ref, query) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get<Map<String, dynamic>>('/admin/webhooks', queryParameters: query);
  return response.isSuccess ? response.data : null;
});

final adminWebhookDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, id) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get<Map<String, dynamic>>('/admin/webhooks/$id');
  return response.isSuccess ? response.data : null;
});
