import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../data/admin_repository.dart';

final adminStatsProvider = FutureProvider<AdminStats?>((ref) async {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.getStats();
});
