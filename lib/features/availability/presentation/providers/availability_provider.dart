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

class AvailabilityQuery {
  final String facilityId;
  final String date;

  const AvailabilityQuery({required this.facilityId, required this.date});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AvailabilityQuery &&
          runtimeType == other.runtimeType &&
          facilityId == other.facilityId &&
          date == other.date;

  @override
  int get hashCode => facilityId.hashCode ^ date.hashCode;
}

final availabilityFutureProvider = FutureProvider.family<Availability?, AvailabilityQuery>((ref, query) async {
  final repository = ref.watch(availabilityRepositoryProvider);
  return repository.getAvailability(facilityId: query.facilityId, date: query.date);
});
