import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/bootstrap/bootstrap.dart';

final adminFinanceOverviewProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get<Map<String, dynamic>>('/admin/finance/overview');
  return response.isSuccess ? response.data : null;
});

final adminReconciliationProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, Map<String, String>>((ref, query) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get<Map<String, dynamic>>('/admin/finance/reconciliation', queryParameters: query);
  return response.isSuccess ? response.data : null;
});

final adminCommissionsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get<List<dynamic>>('/admin/finance/commissions');
  return response.isSuccess ? (response.data ?? []) : [];
});

final adminSettlementsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get<List<dynamic>>('/admin/finance/settlements');
  return response.isSuccess ? (response.data ?? []) : [];
});

final adminPayoutsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.get<List<dynamic>>('/admin/finance/payouts');
  return response.isSuccess ? (response.data ?? []) : [];
});
