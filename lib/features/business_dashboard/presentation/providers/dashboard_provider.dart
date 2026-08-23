import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../data/dashboard_repository.dart';

final dashboardStatsProvider = FutureProvider<DashboardStats?>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getStats();
});
