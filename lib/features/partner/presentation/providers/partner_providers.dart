import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/bootstrap/bootstrap.dart';
import '../../../../core/security/auth_provider.dart';
import '../../../business_dashboard/data/dashboard_repository.dart';
import '../../data/partner_repository.dart';
import '../../domain/models/partner_models.dart';

export '../../domain/models/partner_models.dart';
export '../../../business_dashboard/data/dashboard_repository.dart';

final partnerRepositoryProvider = Provider<IPartnerRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PartnerRepositoryImpl(apiClient);
});

final myPartnerOrganizationsProvider = FutureProvider<List<PartnerOrganization>>((ref) async {
  final repo = ref.watch(partnerRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  if (authState.identity == null) return const [];
  return repo.getMyOrganizations();
});

final selectedPartnerOrgIdProvider = StateProvider<String?>((ref) {
  final activeOrgId = ref.watch(activeOrganizationProvider);
  return activeOrgId;
});

final currentPartnerOrgProvider = Provider<PartnerOrganization?>((ref) {
  final orgsAsync = ref.watch(myPartnerOrganizationsProvider);
  final selectedId = ref.watch(selectedPartnerOrgIdProvider);

  return orgsAsync.when(
    data: (orgs) {
      if (orgs.isEmpty) return null;
      if (selectedId == null) return orgs.first;
      return orgs.firstWhere((o) => o.id == selectedId, orElse: () => orgs.first);
    },
    loading: () => null,
    error: (err, stack) => null,
  );
});

final partnerStatsProvider = FutureProvider.autoDispose<DashboardStats?>((ref) async {
  final repo = ref.watch(partnerRepositoryProvider);
  final currentOrg = ref.watch(currentPartnerOrgProvider);
  final orgId = currentOrg?.id ?? 'default_org';
  return repo.getDashboardStats(orgId);
});

final partnerVenuesProvider = FutureProvider.autoDispose<List<PartnerVenue>>((ref) async {
  final repo = ref.watch(partnerRepositoryProvider);
  final currentOrg = ref.watch(currentPartnerOrgProvider);
  final orgId = currentOrg?.id ?? 'default_org';
  return repo.getVenues(orgId);
});

final partnerVenueDetailsProvider = FutureProvider.autoDispose.family<PartnerVenue?, String>((ref, venueId) async {
  final repo = ref.watch(partnerRepositoryProvider);
  final currentOrg = ref.watch(currentPartnerOrgProvider);
  final orgId = currentOrg?.id ?? 'default_org';
  return repo.getVenueDetails(orgId, venueId);
});

final partnerFacilitiesProvider = FutureProvider.autoDispose.family<List<PartnerFacility>, String>((ref, venueId) async {
  final repo = ref.watch(partnerRepositoryProvider);
  final currentOrg = ref.watch(currentPartnerOrgProvider);
  final orgId = currentOrg?.id ?? 'default_org';
  return repo.getFacilities(orgId, venueId);
});

final partnerBookingsProvider = FutureProvider.autoDispose<List<PartnerBookingItem>>((ref) async {
  final repo = ref.watch(partnerRepositoryProvider);
  final currentOrg = ref.watch(currentPartnerOrgProvider);
  final orgId = currentOrg?.id ?? 'default_org';
  return repo.getBookings(orgId);
});

final partnerBookingDetailsProvider = FutureProvider.autoDispose.family<PartnerBookingItem?, String>((ref, bookingId) async {
  final bookingsAsync = await ref.watch(partnerBookingsProvider.future);
  return bookingsAsync.firstWhere((b) => b.id == bookingId);
});

final partnerPricingRulesProvider = FutureProvider.autoDispose.family<List<PricingRule>, String>((ref, facilityId) async {
  final repo = ref.watch(partnerRepositoryProvider);
  final currentOrg = ref.watch(currentPartnerOrgProvider);
  if (currentOrg == null) return const [];
  return repo.getPricingRules(currentOrg.id, facilityId);
});
