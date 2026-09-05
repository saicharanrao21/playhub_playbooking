import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/bootstrap/bootstrap.dart';
import '../../../../core/security/auth_provider.dart';

final partnerAnalyticsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, preset) async {
  final apiClient = ref.watch(apiClientProvider);
  final orgId = ref.watch(activeOrganizationProvider);
  if (orgId == null) return null;

  final response = await apiClient.get<Map<String, dynamic>>(
    '/organizations/$orgId/analytics/dashboard',
    queryParameters: {'preset': preset},
  );
  return response.isSuccess ? response.data : null;
});

final partnerPeakTimesProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, preset) async {
  final apiClient = ref.watch(apiClientProvider);
  final orgId = ref.watch(activeOrganizationProvider);
  if (orgId == null) return null;

  final response = await apiClient.get<Map<String, dynamic>>(
    '/organizations/$orgId/analytics/peak-times',
    queryParameters: {'preset': preset},
  );
  return response.isSuccess ? response.data : null;
});
