import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../data/admin_repository.dart';
import '../../data/admin_models.dart';

final adminStatsProvider = FutureProvider.autoDispose<AdminStats?>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getStats();
});

final adminPartnersProvider = FutureProvider.autoDispose.family<List<AdminPartner>, String?>((ref, kycStatus) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getPartners(kycStatus: kycStatus);
});

final adminAuditLogsProvider = FutureProvider.autoDispose<List<AdminAuditLog>>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getAuditLogs();
});

final adminPartnerDetailsProvider = FutureProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, id) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getPartnerDetails(id);
});
