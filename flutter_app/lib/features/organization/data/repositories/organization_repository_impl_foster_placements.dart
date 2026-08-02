import '../../../../core/utils/calendar_date.dart';
import '../../domain/entities/foster_placement.dart';
import 'organization_repository_impl_base.dart';

mixin OrganizationRepositoryFosterPlacementsMixin
    on OrganizationRepositoryImplBase {
  @override
  Future<List<FosterPlacement>> getOrganizationPlacements(
    String orgId,
    String token, {
    Map<String, String>? filters,
  }) async {
    final rows = await dataSource.getOrganizationPlacements(
      orgId,
      token,
      filters: filters,
    );
    return rows.map(FosterPlacement.fromJson).toList();
  }

  @override
  Future<PetFosterPlacementState> getPetPlacement(
    String orgId,
    String petId,
    String token,
  ) async {
    final row = await dataSource.getPetPlacement(orgId, petId, token);
    return PetFosterPlacementState.fromJson(row);
  }

  @override
  Future<FosterPlacement> startFosterPlacement(
    String orgId,
    String petId, {
    required String fosterUserId,
    DateTime? startDate,
    String notes = '',
    required String token,
  }) async {
    final row = await dataSource.startFosterPlacement(
      orgId,
      petId,
      fosterUserId: fosterUserId,
      startDate: startDate != null ? toCalendarDateString(startDate) : null,
      notes: notes,
      token: token,
    );
    return FosterPlacement.fromJson(row);
  }

  @override
  Future<FosterPlacement> endFosterPlacement(
    String orgId,
    String placementId, {
    DateTime? endDate,
    required String token,
  }) async {
    final row = await dataSource.endFosterPlacement(
      orgId,
      placementId,
      endDate: endDate != null ? toCalendarDateString(endDate) : null,
      token: token,
    );
    return FosterPlacement.fromJson(row);
  }

  @override
  Future<FosterPlacement> startAdoption(
    String orgId,
    String placementId, {
    String adoptionConditions = '',
    required String token,
  }) async {
    final row = await dataSource.startAdoption(
      orgId,
      placementId,
      adoptionConditions: adoptionConditions,
      token: token,
    );
    return FosterPlacement.fromJson(row);
  }

  @override
  Future<FosterPlacement> completeAdoptionConditions(
    String orgId,
    String placementId, {
    required String token,
  }) async {
    final row = await dataSource.completeAdoptionConditions(
      orgId,
      placementId,
      token: token,
    );
    return FosterPlacement.fromJson(row);
  }

  @override
  Future<FosterPlacement> cancelAdoption(
    String orgId,
    String placementId, {
    DateTime? endDate,
    required String token,
  }) async {
    final row = await dataSource.cancelAdoption(
      orgId,
      placementId,
      endDate: endDate != null ? toCalendarDateString(endDate) : null,
      token: token,
    );
    return FosterPlacement.fromJson(row);
  }

  @override
  Future<FosterPlacement> directAdopt(
    String orgId,
    String petId, {
    required String fosterUserId,
    String adoptionConditions = '',
    String notes = '',
    required String token,
  }) async {
    final row = await dataSource.directAdopt(
      orgId,
      petId,
      fosterUserId: fosterUserId,
      adoptionConditions: adoptionConditions,
      notes: notes,
      token: token,
    );
    return FosterPlacement.fromJson(row);
  }

  @override
  Future<List<FosterPlacement>> getPetFosterHistory(
    String orgId,
    String petId,
    String token,
  ) async {
    final rows = await dataSource.getPetFosterHistory(orgId, petId, token);
    return rows.map(FosterPlacement.fromJson).toList();
  }

  @override
  Future<FosterPlacement> getPlacementDetail(
    String orgId,
    String placementId,
    String token,
  ) async {
    final row = await dataSource.getPlacementDetail(orgId, placementId, token);
    return FosterPlacement.fromJson(row);
  }

  @override
  Future<FosterPlacement> transitionFosteringSession(
    String orgId,
    String placementId, {
    required String sessionStatus,
    required String token,
  }) async {
    final row = await dataSource.transitionFosteringSession(
      orgId,
      placementId,
      sessionStatus: sessionStatus,
      token: token,
    );
    return FosterPlacement.fromJson(row);
  }

  @override
  Future<FosterPlacement> confirmShelterSessionStart(
    String orgId,
    String placementId, {
    required String token,
  }) async {
    final row = await dataSource.confirmShelterSessionStart(
      orgId,
      placementId,
      token: token,
    );
    return FosterPlacement.fromJson(row);
  }

  @override
  Future<FosterPlacement> confirmFosterSessionStart(
    String orgId,
    String placementId, {
    required String token,
  }) async {
    final row = await dataSource.confirmFosterSessionStart(
      orgId,
      placementId,
      token: token,
    );
    return FosterPlacement.fromJson(row);
  }

  @override
  Future<FosterPlacement> requestFosteringSessionEnd(
    String orgId,
    String placementId, {
    required String token,
  }) async {
    final row = await dataSource.requestFosteringSessionEnd(
      orgId,
      placementId,
      token: token,
    );
    return FosterPlacement.fromJson(row);
  }

  @override
  Future<FosterPlacement> endFosteringSession(
    String orgId,
    String placementId, {
    required String outcome,
    DateTime? endDate,
    required String token,
  }) async {
    final row = await dataSource.endFosteringSession(
      orgId,
      placementId,
      outcome: outcome,
      endDate: endDate != null ? toCalendarDateString(endDate) : null,
      token: token,
    );
    return FosterPlacement.fromJson(row);
  }
}
