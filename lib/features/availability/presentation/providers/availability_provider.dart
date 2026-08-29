import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/availability_repository.dart';
import '../../domain/models/availability_models.dart';
import 'package:playhub_playbooking/app/bootstrap/bootstrap.dart';
import 'package:playhub_playbooking/core/security/auth_provider.dart';

final availabilityRepositoryProvider = Provider<AvailabilityRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final orgId = ref.watch(activeOrganizationProvider) ?? '';
  return AvailabilityRepository(apiClient, orgId);
});

final availabilityFutureProvider = FutureProvider.family<Availability?, AvailabilityQuery>((ref, query) async {
  final repository = ref.watch(availabilityRepositoryProvider);
  return repository.getAvailability(facilityId: query.facilityId, date: query.date);
});
