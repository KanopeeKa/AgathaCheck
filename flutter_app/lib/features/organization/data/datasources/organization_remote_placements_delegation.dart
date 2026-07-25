import 'organization_remote/organization_placements_remote.dart';

mixin OrganizationRemotePlacementsDelegation {
  OrganizationPlacementsRemote get placementsRemote;

  Future<Map<String, dynamic>> getPetPlacement(
    String orgId,
    String petId,
    String token,
  ) => placementsRemote.getPetPlacement(orgId, petId, token);

  Future<Map<String, dynamic>> startFosterPlacement(
    String orgId,
    String petId, {
    required String fosterUserId,
    String? startDate,
    String notes = '',
    required String token,
  }) => placementsRemote.startFosterPlacement(
    orgId,
    petId,
    fosterUserId: fosterUserId,
    startDate: startDate,
    notes: notes,
    token: token,
  );

  Future<Map<String, dynamic>> endFosterPlacement(
    String orgId,
    String placementId, {
    String? endDate,
    required String token,
  }) => placementsRemote.endFosterPlacement(
    orgId,
    placementId,
    endDate: endDate,
    token: token,
  );

  Future<Map<String, dynamic>> startAdoption(
    String orgId,
    String placementId, {
    String adoptionConditions = '',
    required String token,
  }) => placementsRemote.startAdoption(
    orgId,
    placementId,
    adoptionConditions: adoptionConditions,
    token: token,
  );

  Future<Map<String, dynamic>> completeAdoptionConditions(
    String orgId,
    String placementId, {
    required String token,
  }) => placementsRemote.completeAdoptionConditions(
    orgId,
    placementId,
    token: token,
  );

  Future<Map<String, dynamic>> cancelAdoption(
    String orgId,
    String placementId, {
    String? endDate,
    required String token,
  }) => placementsRemote.cancelAdoption(
    orgId,
    placementId,
    endDate: endDate,
    token: token,
  );

  Future<Map<String, dynamic>> directAdopt(
    String orgId,
    String petId, {
    required String fosterUserId,
    String adoptionConditions = '',
    String notes = '',
    required String token,
  }) => placementsRemote.directAdopt(
    orgId,
    petId,
    fosterUserId: fosterUserId,
    adoptionConditions: adoptionConditions,
    notes: notes,
    token: token,
  );

  Future<List<Map<String, dynamic>>> getPetFosterHistory(
    String orgId,
    String petId,
    String token,
  ) => placementsRemote.getPetFosterHistory(orgId, petId, token);

  Future<Map<String, dynamic>> getPlacementDetail(
    String orgId,
    String placementId,
    String token,
  ) => placementsRemote.getPlacementDetail(orgId, placementId, token);

  Future<Map<String, dynamic>> transitionFosteringSession(
    String orgId,
    String placementId, {
    required String sessionStatus,
    required String token,
  }) => placementsRemote.transitionFosteringSession(
    orgId,
    placementId,
    sessionStatus: sessionStatus,
    token: token,
  );

  Future<Map<String, dynamic>> confirmShelterSessionStart(
    String orgId,
    String placementId, {
    required String token,
  }) => placementsRemote.confirmShelterSessionStart(
    orgId,
    placementId,
    token: token,
  );

  Future<Map<String, dynamic>> confirmFosterSessionStart(
    String orgId,
    String placementId, {
    required String token,
  }) => placementsRemote.confirmFosterSessionStart(
    orgId,
    placementId,
    token: token,
  );

  Future<Map<String, dynamic>> requestFosteringSessionEnd(
    String orgId,
    String placementId, {
    required String token,
  }) => placementsRemote.requestFosteringSessionEnd(
    orgId,
    placementId,
    token: token,
  );

  Future<Map<String, dynamic>> endFosteringSession(
    String orgId,
    String placementId, {
    required String outcome,
    String? endDate,
    required String token,
  }) => placementsRemote.endFosteringSession(
    orgId,
    placementId,
    outcome: outcome,
    endDate: endDate,
    token: token,
  );
}
