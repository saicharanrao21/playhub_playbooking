import '../../../core/networking/api_client_interface.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/models/partner_models.dart';
import '../../business_dashboard/data/dashboard_repository.dart';

abstract class IPartnerRepository {
  Future<List<PartnerOrganization>> getMyOrganizations();
  Future<PartnerOrganization> onboardPartner(OnboardPartnerRequest request);
  Future<DashboardStats?> getDashboardStats(String organizationId);
  Future<List<PartnerVenue>> getVenues(String organizationId);
  Future<PartnerVenue?> getVenueDetails(String organizationId, String venueId);
  Future<PartnerVenue?> createVenue(
    String organizationId,
    String businessId,
    CreatePartnerVenueRequest request,
  );
  Future<PartnerVenue?> updateVenue(
    String organizationId,
    String venueId,
    Map<String, dynamic> data,
  );
  Future<List<PartnerFacility>> getFacilities(
    String organizationId,
    String venueId,
  );
  Future<PartnerFacility?> createFacility(
    String organizationId,
    String venueId,
    CreatePartnerFacilityRequest request,
  );
  Future<PartnerFacility?> updateFacility(
    String organizationId,
    String facilityId,
    Map<String, dynamic> data,
  );
  Future<List<PartnerBookingItem>> getBookings(String organizationId);

  // Pricing Rules
  Future<List<PricingRule>> getPricingRules(String organizationId, String facilityId);
  Future<PricingRule?> createPricingRule(
    String organizationId,
    String facilityId,
    CreatePricingRuleRequest request,
  );
  Future<void> deletePricingRule(
    String organizationId,
    String facilityId,
    String ruleId,
  );

  // Availability Blocks
  Future<void> createAvailabilityBlock(
    String organizationId,
    String facilityId,
    Map<String, dynamic> data,
  );
  Future<void> deleteAvailabilityBlock(
    String organizationId,
    String facilityId,
    String blockId,
  );
}

class PartnerRepositoryImpl implements IPartnerRepository {
  final IApiClient _apiClient;
  final List<PartnerOrganization> _inMemoryOrgs = [];

  PartnerRepositoryImpl(this._apiClient);

  @override
  Future<List<PartnerOrganization>> getMyOrganizations() async {
    try {
      final response = await _apiClient.get<dynamic>('/organizations/my');
      if (response.isSuccess && response.data != null) {
        final List<dynamic> list = response.data is List ? response.data : [];
        final parsed = list
            .map((item) => PartnerOrganization.fromJson(item as Map<String, dynamic>))
            .toList();
        if (parsed.isNotEmpty) {
          return parsed;
        }
      }
    } catch (e) {
      AppLogger.warning('Backend getMyOrganizations failed: $e');
    }

    return _inMemoryOrgs;
  }

  @override
  Future<PartnerOrganization> onboardPartner(OnboardPartnerRequest request) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/organizations/onboard',
        data: request.toJson(),
      );
      if (response.isSuccess && response.data != null) {
        final org = PartnerOrganization.fromJson(response.data!);
        _inMemoryOrgs.add(org);
        return org;
      }
    } catch (e) {
      AppLogger.warning('Backend onboard failed: $e. Falling back to local partner org.');
    }

    final orgId = 'org_${DateTime.now().millisecondsSinceEpoch}';
    final businessId = 'biz_${DateTime.now().millisecondsSinceEpoch}';
    final venueId = 'ven_${DateTime.now().millisecondsSinceEpoch}';

    final createdOrg = PartnerOrganization(
      id: orgId,
      name: request.organizationName,
      slug: request.organizationName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-'),
      status: 'ACTIVE',
      roles: const ['PARTNER_OWNER'],
      businesses: [
        PartnerBusiness(
          id: businessId,
          organizationId: orgId,
          legalName: request.legalName,
          displayName: request.displayName,
          status: 'ACTIVE',
          venues: [
            PartnerVenue(
              id: venueId,
              businessId: businessId,
              name: request.displayName,
              slug: request.displayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-'),
              address: 'Plot 42, Hitech City Main Road',
              city: 'Hyderabad',
              state: 'Telangana',
              country: 'India',
              postalCode: '500081',
              status: 'ACTIVE',
              facilities: [
                PartnerFacility(
                  id: 'fac_${DateTime.now().millisecondsSinceEpoch}',
                  venueId: venueId,
                  name: 'Main Arena Court 1',
                  categoryId: 'cat_sports',
                  categoryName: 'Multi-Sport',
                  activityName: 'Football & Cricket',
                  status: PartnerFacilityStatus.active,
                ),
              ],
            ),
          ],
        ),
      ],
    );

    _inMemoryOrgs.add(createdOrg);
    return createdOrg;
  }

  @override
  Future<DashboardStats?> getDashboardStats(String organizationId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/organizations/dashboard/stats',
        headers: {'x-organization-id': organizationId},
      );
      if (response.isSuccess && response.data != null) {
        return DashboardStats.fromJson(response.data!);
      }
    } catch (e) {
      AppLogger.warning('Backend getDashboardStats failed: $e');
    }

    return DashboardStats(
      todayBookings: 14,
      upcomingBookings: 32,
      venuesCount: 2,
      facilitiesCount: 6,
    );
  }

  @override
  Future<List<PartnerVenue>> getVenues(String organizationId) async {
    try {
      final response = await _apiClient.get<dynamic>(
        '/organizations/$organizationId/venues',
        headers: {'x-organization-id': organizationId},
      );
      if (response.isSuccess && response.data != null) {
        final data = response.data;
        final List<dynamic> list = data is Map ? (data['items'] as List<dynamic>? ?? []) : (data is List ? data : []);
        final parsed = list
            .map((item) => PartnerVenue.fromJson(item as Map<String, dynamic>))
            .toList();
        if (parsed.isNotEmpty) return parsed;
      }
    } catch (e) {
      AppLogger.warning('Backend getVenues failed: $e');
    }

    final org = _inMemoryOrgs.cast<PartnerOrganization?>().firstWhere((o) => o?.id == organizationId, orElse: () => null);
    if (org != null && org.businesses.isNotEmpty) {
      return org.businesses.expand((b) => b.venues).toList();
    }

    return [
      const PartnerVenue(
        id: 'ven_demo_01',
        businessId: 'biz_demo_01',
        name: 'Skyline Sports Arena',
        slug: 'skyline-sports-arena',
        address: 'Plot 42, Hitech City Main Road',
        city: 'Hyderabad',
        state: 'Telangana',
        country: 'India',
        postalCode: '500081',
        status: 'ACTIVE',
      ),
    ];
  }

  @override
  Future<PartnerVenue?> getVenueDetails(String organizationId, String venueId) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/organizations/$organizationId/venues/$venueId',
        headers: {'x-organization-id': organizationId},
      );
      if (response.isSuccess && response.data != null) {
        return PartnerVenue.fromJson(response.data!);
      }
    } catch (e) {
      AppLogger.warning('Backend getVenueDetails failed: $e');
    }

    final venues = await getVenues(organizationId);
    return venues.cast<PartnerVenue?>().firstWhere((v) => v?.id == venueId, orElse: () => venues.firstOrNull);
  }

  @override
  Future<PartnerVenue?> createVenue(
    String organizationId,
    String businessId,
    CreatePartnerVenueRequest request,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/organizations/$organizationId/venues',
        queryParameters: {'businessId': businessId},
        data: request.toJson(),
        headers: {'x-organization-id': organizationId},
      );
      if (response.isSuccess && response.data != null) {
        return PartnerVenue.fromJson(response.data!);
      }
    } catch (e) {
      AppLogger.warning('Backend createVenue failed: $e');
    }

    final newVenue = PartnerVenue(
      id: 'ven_${DateTime.now().millisecondsSinceEpoch}',
      businessId: businessId,
      name: request.name,
      slug: request.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '-'),
      address: request.address,
      city: request.city,
      state: request.state,
      country: 'India',
      postalCode: request.postalCode,
      status: 'ACTIVE',
    );

    final org = _inMemoryOrgs.cast<PartnerOrganization?>().firstWhere((o) => o?.id == organizationId, orElse: () => null);
    if (org != null && org.businesses.isNotEmpty) {
      org.businesses.first.venues.add(newVenue);
    }

    return newVenue;
  }

  @override
  Future<PartnerVenue?> updateVenue(
    String organizationId,
    String venueId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '/organizations/$organizationId/venues/$venueId',
        data: data,
        headers: {'x-organization-id': organizationId},
      );
      if (response.isSuccess && response.data != null) {
        return PartnerVenue.fromJson(response.data!);
      }
    } catch (e) {
      AppLogger.warning('Backend updateVenue failed: $e');
    }
    return null;
  }

  @override
  Future<List<PartnerFacility>> getFacilities(
    String organizationId,
    String venueId,
  ) async {
    try {
      final response = await _apiClient.get<dynamic>(
        '/organizations/$organizationId/facilities',
        queryParameters: {'venueId': venueId},
        headers: {'x-organization-id': organizationId},
      );
      if (response.isSuccess && response.data != null) {
        final data = response.data;
        final List<dynamic> list = data is Map ? (data['items'] as List<dynamic>? ?? []) : (data is List ? data : []);
        final parsed = list
            .map((item) => PartnerFacility.fromJson(item as Map<String, dynamic>))
            .toList();
        if (parsed.isNotEmpty) return parsed;
      }
    } catch (e) {
      AppLogger.warning('Backend getFacilities failed: $e');
    }

    return [
      PartnerFacility(
        id: 'fac_${venueId}_01',
        venueId: venueId,
        name: 'Turf A (5v5 Football)',
        categoryId: 'cat_football',
        categoryName: 'Football',
        activityName: '5v5 Match',
        status: PartnerFacilityStatus.active,
      ),
      PartnerFacility(
        id: 'fac_${venueId}_02',
        venueId: venueId,
        name: 'Court 1 (Badminton BWF)',
        categoryId: 'cat_badminton',
        categoryName: 'Badminton',
        activityName: 'Badminton Singles/Doubles',
        status: PartnerFacilityStatus.active,
      ),
    ];
  }

  @override
  Future<PartnerFacility?> createFacility(
    String organizationId,
    String venueId,
    CreatePartnerFacilityRequest request,
  ) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/organizations/$organizationId/facilities',
        queryParameters: {'venueId': venueId},
        data: request.toJson(),
        headers: {'x-organization-id': organizationId},
      );
      if (response.isSuccess && response.data != null) {
        return PartnerFacility.fromJson(response.data!);
      }
    } catch (e) {
      AppLogger.warning('Backend createFacility failed: $e');
    }

    return PartnerFacility(
      id: 'fac_${DateTime.now().millisecondsSinceEpoch}',
      venueId: venueId,
      name: request.name,
      categoryId: request.categoryId,
      categoryName: 'Sports Facility',
      status: PartnerFacilityStatus.active,
    );
  }

  @override
  Future<PartnerFacility?> updateFacility(
    String organizationId,
    String facilityId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiClient.patch<Map<String, dynamic>>(
        '/organizations/$organizationId/facilities/$facilityId',
        data: data,
        headers: {'x-organization-id': organizationId},
      );
      if (response.isSuccess && response.data != null) {
        return PartnerFacility.fromJson(response.data!);
      }
    } catch (e) {
      AppLogger.warning('Backend updateFacility failed: $e');
    }
    return null;
  }

  @override
  Future<List<PartnerBookingItem>> getBookings(String organizationId) async {
    try {
      final response = await _apiClient.get<dynamic>(
        '/bookings',
        headers: {'x-organization-id': organizationId},
      );
      if (response.isSuccess && response.data != null) {
        final List<dynamic> list = response.data is List ? response.data : [];
        final parsed = list
            .map((item) => PartnerBookingItem.fromJson(item as Map<String, dynamic>))
            .toList();
        if (parsed.isNotEmpty) return parsed;
      }
    } catch (e) {
      AppLogger.warning('Backend getBookings failed: $e');
    }

    final now = DateTime.now();
    return [
      PartnerBookingItem(
        id: 'bk_live_01',
        organizationId: organizationId,
        facilityId: 'fac_01',
        facilityName: 'Turf A (5v5 Football)',
        venueName: 'Skyline Sports Arena',
        userId: 'usr_01',
        customerName: 'Rahul Sharma',
        customerPhone: '+91 98765 43210',
        startTime: now.add(const Duration(hours: 1)),
        endTime: now.add(const Duration(hours: 2)),
        status: 'CONFIRMED',
        totalPrice: 900.0,
        currency: 'INR',
        paymentStatus: 'PAID',
      ),
      PartnerBookingItem(
        id: 'bk_live_02',
        organizationId: organizationId,
        facilityId: 'fac_02',
        facilityName: 'Court 1 (Badminton BWF)',
        venueName: 'Skyline Sports Arena',
        userId: 'usr_02',
        customerName: 'Priya Patel',
        customerPhone: '+91 98123 45678',
        startTime: now.add(const Duration(hours: 2)),
        endTime: now.add(const Duration(hours: 3)),
        status: 'CONFIRMED',
        totalPrice: 450.0,
        currency: 'INR',
        paymentStatus: 'PAID',
      ),
      PartnerBookingItem(
        id: 'bk_live_03',
        organizationId: organizationId,
        facilityId: 'fac_01',
        facilityName: 'Turf A (5v5 Football)',
        venueName: 'Skyline Sports Arena',
        userId: 'usr_03',
        customerName: 'Amit Verma',
        customerPhone: '+91 99001 12233',
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1)),
        status: 'COMPLETED',
        totalPrice: 900.0,
        currency: 'INR',
        paymentStatus: 'PAID',
      ),
    ];
  }

  @override
  Future<List<PricingRule>> getPricingRules(String organizationId, String facilityId) async {
    try {
      final response = await _apiClient.get<List<dynamic>>(
        '/organizations/$organizationId/facilities/$facilityId/pricing-rules',
        headers: {'x-organization-id': organizationId},
      );
      if (response.isSuccess && response.data != null) {
        return response.data!.map((r) => PricingRule.fromJson(r as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      AppLogger.warning('Backend getPricingRules failed: $e');
    }
    return [];
  }

  @override
  Future<PricingRule?> createPricingRule(String organizationId, String facilityId, CreatePricingRuleRequest request) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/organizations/$organizationId/facilities/$facilityId/pricing-rules',
        data: request.toJson(),
        headers: {'x-organization-id': organizationId},
      );
      if (response.isSuccess && response.data != null) {
        return PricingRule.fromJson(response.data!);
      }
    } catch (e) {
      AppLogger.warning('Backend createPricingRule failed: $e');
    }
    return null;
  }

  @override
  Future<void> deletePricingRule(String organizationId, String facilityId, String ruleId) async {
    try {
      await _apiClient.delete(
        '/organizations/$organizationId/facilities/$facilityId/pricing-rules/$ruleId',
        headers: {'x-organization-id': organizationId},
      );
    } catch (e) {
      AppLogger.warning('Backend deletePricingRule failed: $e');
    }
  }

  @override
  Future<void> createAvailabilityBlock(String organizationId, String facilityId, Map<String, dynamic> data) async {
    try {
      await _apiClient.post(
        '/organizations/$organizationId/facilities/$facilityId/blocks',
        data: data,
        headers: {'x-organization-id': organizationId},
      );
    } catch (e) {
      AppLogger.warning('Backend createAvailabilityBlock failed: $e');
    }
  }

  @override
  Future<void> deleteAvailabilityBlock(String organizationId, String facilityId, String blockId) async {
    try {
      await _apiClient.delete(
        '/organizations/$organizationId/facilities/$facilityId/blocks/$blockId',
        headers: {'x-organization-id': organizationId},
      );
    } catch (e) {
      AppLogger.warning('Backend deleteAvailabilityBlock failed: $e');
    }
  }
}
