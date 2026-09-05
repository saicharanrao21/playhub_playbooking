import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/bootstrap/bootstrap.dart';

final mySupportTicketsProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get<Map<String, dynamic>>('/support/tickets');
  return response.isSuccess ? response.data : null;
});

final ticketDetailsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, id) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get<Map<String, dynamic>>('/support/tickets/$id');
  return response.isSuccess ? response.data : null;
});
