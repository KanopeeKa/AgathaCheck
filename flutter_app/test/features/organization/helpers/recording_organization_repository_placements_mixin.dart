import 'package:pet_profile_app/features/organization/domain/entities/foster_placement.dart';

import 'recording_organization_repository_base.dart';

mixin RecordingOrganizationRepositoryPlacementsMixin
    on RecordingOrganizationRepositoryBase {
  @override
  Future<PetFosterPlacementState> getPetPlacement(
    String orgId,
    String petId,
    String token,
  ) async => const PetFosterPlacementState(status: 'not_in_foster');

  @override
  Future<FosterPlacement> startFosterPlacement(
    String orgId,
    String petId, {
    required String fosterUserId,
    DateTime? startDate,
    String notes = '',
    required String token,
  }) async => FosterPlacement(
    id: 'fp-1',
    organizationId: orgId,
    petId: petId,
    fosterUserId: fosterUserId,
    status: 'pending',
  );

  @override
  Future<FosterPlacement> endFosterPlacement(
    String orgId,
    String placementId, {
    DateTime? endDate,
    required String token,
  }) async => FosterPlacement(
    id: placementId,
    organizationId: orgId,
    petId: 'pet-1',
    fosterUserId: 'user-1',
    status: 'not_in_foster',
  );

  @override
  Future<FosterPlacement> startAdoption(
    String orgId,
    String placementId, {
    String adoptionConditions = '',
    required String token,
  }) async => FosterPlacement(
    id: placementId,
    organizationId: orgId,
    petId: 'pet-1',
    fosterUserId: 'user-1',
    status: 'waiting_adoption_confirmation',
  );

  @override
  Future<FosterPlacement> completeAdoptionConditions(
    String orgId,
    String placementId, {
    required String token,
  }) async => FosterPlacement(
    id: placementId,
    organizationId: orgId,
    petId: 'pet-1',
    fosterUserId: 'user-1',
    status: 'waiting_adoption_confirmation',
  );

  @override
  Future<FosterPlacement> cancelAdoption(
    String orgId,
    String placementId, {
    DateTime? endDate,
    required String token,
  }) async => FosterPlacement(
    id: placementId,
    organizationId: orgId,
    petId: 'pet-1',
    fosterUserId: 'user-1',
    status: 'not_in_foster',
  );

  @override
  Future<FosterPlacement> directAdopt(
    String orgId,
    String petId, {
    required String fosterUserId,
    String adoptionConditions = '',
    String notes = '',
    required String token,
  }) async => FosterPlacement(
    id: 'fp-direct',
    organizationId: orgId,
    petId: petId,
    fosterUserId: fosterUserId,
    status: 'waiting_adoption_confirmation',
  );

  @override
  Future<List<FosterPlacement>> getPetFosterHistory(
    String orgId,
    String petId,
    String token,
  ) async => [];

  @override
  Future<FosterPlacement> getPlacementDetail(
    String orgId,
    String placementId,
    String token,
  ) async => FosterPlacement(
    id: placementId,
    organizationId: orgId,
    petId: 'pet-1',
    fosterUserId: 'user-1',
    status: 'pending',
    sessionStatus: 'preparation',
    petName: 'Max',
    fosterName: 'Jane Foster',
  );

  @override
  Future<FosterPlacement> transitionFosteringSession(
    String orgId,
    String placementId, {
    required String sessionStatus,
    required String token,
  }) async => FosterPlacement(
    id: placementId,
    organizationId: orgId,
    petId: 'pet-1',
    fosterUserId: 'user-1',
    status: 'pending',
    sessionStatus: sessionStatus,
    petName: 'Max',
    fosterName: 'Jane Foster',
  );

  @override
  Future<FosterPlacement> confirmShelterSessionStart(
    String orgId,
    String placementId, {
    required String token,
  }) async => FosterPlacement(
    id: placementId,
    organizationId: orgId,
    petId: 'pet-1',
    fosterUserId: 'user-1',
    status: 'pending',
    sessionStatus: 'ready_to_start',
    shelterStartConfirmedAt: DateTime(2024, 1, 2),
    petName: 'Max',
    fosterName: 'Jane Foster',
  );

  @override
  Future<FosterPlacement> confirmFosterSessionStart(
    String orgId,
    String placementId, {
    required String token,
  }) async => FosterPlacement(
    id: placementId,
    organizationId: orgId,
    petId: 'pet-1',
    fosterUserId: 'user-1',
    status: 'in_progress',
    sessionStatus: 'active',
    fosterStartConfirmedAt: DateTime(2024, 1, 2),
    petName: 'Max',
    fosterName: 'Jane Foster',
  );

  @override
  Future<FosterPlacement> requestFosteringSessionEnd(
    String orgId,
    String placementId, {
    required String token,
  }) async => FosterPlacement(
    id: placementId,
    organizationId: orgId,
    petId: 'pet-1',
    fosterUserId: 'user-1',
    status: 'in_progress',
    sessionStatus: 'end_pending_confirmation',
    petName: 'Max',
    fosterName: 'Jane Foster',
  );

  @override
  Future<FosterPlacement> endFosteringSession(
    String orgId,
    String placementId, {
    required String outcome,
    DateTime? endDate,
    required String token,
  }) async => FosterPlacement(
    id: placementId,
    organizationId: orgId,
    petId: 'pet-1',
    fosterUserId: 'user-1',
    status: 'not_in_foster',
    sessionStatus: outcome,
    petName: 'Max',
    fosterName: 'Jane Foster',
  );
}
