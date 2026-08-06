import 'organization_remote/organization_foster_parents_remote.dart';
import 'organization_remote/organization_foster_requests_remote.dart';
import 'organization_remote/organization_placements_remote.dart';

/// Foster-parent, foster-request, and placement delegations for
/// [OrganizationRemoteDataSource].
mixin OrganizationRemoteFosterDelegations {
  OrganizationFosterParentsRemote get fosterParentsRemote;
  OrganizationFosterRequestsRemote get fosterRequestsRemote;
  OrganizationPlacementsRemote get placementsRemote;

  Future<List<Map<String, dynamic>>> getFosterParents(
    String orgId,
    String token,
  ) => fosterParentsRemote.getFosterParents(orgId, token);

  Future<List<Map<String, dynamic>>> getPeople(String orgId, String token) =>
      fosterParentsRemote.getPeople(orgId, token);

  Future<Map<String, dynamic>> getPersonDetail(
    String orgId,
    String kind,
    String recordId,
    String token,
  ) => fosterParentsRemote.getPersonDetail(orgId, kind, recordId, token);

  Future<Map<String, dynamic>> updatePersonContact(
    String orgId,
    String kind,
    String recordId,
    Map<String, dynamic> body,
    String token,
  ) => fosterParentsRemote.updatePersonContact(
    orgId,
    kind,
    recordId,
    body,
    token,
  );

<<<<<<< HEAD
  Future<Map<String, dynamic>> fosterInvite(
    String orgId, {
    String? email,
    List<String>? userIds,
    required String token,
  }) => fosterParentsRemote.fosterInvite(
    orgId,
    {
      if (email != null && email.isNotEmpty) 'email': email,
      if (userIds != null && userIds.isNotEmpty) 'user_ids': userIds,
    },
    token,
  );
=======
  Future<Map<String, dynamic>> confirmFosterOnboardingStep(
    String orgId, String kind, String recordId, String stepKey, String token,
  ) => fosterParentsRemote.confirmFosterOnboardingStep(orgId, kind, recordId, stepKey, token);
>>>>>>> origin/cursor/org-v4-h-foster-timeline-63a7

  Future<Map<String, dynamic>> createExternalFosterParent(
    String orgId, {
    required String displayName,
    required String email,
    String? phone,
    String fosterAddress = '',
    String notes = '',
    required bool lawfulBasisConfirmed,
    required String token,
  }) => fosterParentsRemote.createExternalFosterParent(
    orgId,
    displayName: displayName,
    email: email,
    phone: phone,
    fosterAddress: fosterAddress,
    notes: notes,
    lawfulBasisConfirmed: lawfulBasisConfirmed,
    token: token,
  );

  Future<Map<String, dynamic>> updateExternalFosterParent(
    String orgId,
    String fosterParentId, {
    required String displayName,
    String? email,
    String? phone,
    String notes = '',
    required String token,
  }) => fosterParentsRemote.updateExternalFosterParent(
    orgId,
    fosterParentId,
    displayName: displayName,
    email: email,
    phone: phone,
    notes: notes,
    token: token,
  );

  Future<void> deleteExternalFosterParent(
    String orgId,
    String fosterParentId,
    String token,
  ) => fosterParentsRemote.deleteExternalFosterParent(
    orgId,
    fosterParentId,
    token,
  );

  Future<Map<String, dynamic>> updateFosterApproval(
    String orgId,
    String fosterParentId,
    String approvalState,
    String token,
  ) => fosterParentsRemote.updateFosterApproval(
    orgId,
    fosterParentId,
    approvalState,
    token,
  );

  Future<Map<String, dynamic>> updateFosterOptOut(
    String orgId,
    String fosterParentId,
    bool optOut,
    String token,
  ) => fosterParentsRemote.updateFosterOptOut(
    orgId,
    fosterParentId,
    optOut,
    token,
  );

  Future<Map<String, dynamic>> updateFosterRetentionCategory(
    String orgId,
    String fosterParentId,
    String retentionCategory,
    String token,
  ) => fosterParentsRemote.updateFosterRetentionCategory(
    orgId,
    fosterParentId,
    retentionCategory,
    token,
  );

  Future<Map<String, dynamic>> updateFosterSelfVisibility(
    String orgId,
    Map<String, dynamic> body,
    String token,
  ) => fosterParentsRemote.updateFosterSelfVisibility(orgId, body, token);

  Future<Map<String, dynamic>> withdrawFosterAgreement(
    String orgId,
    String confirmation,
    String token,
  ) => fosterParentsRemote.withdrawFosterAgreement(orgId, confirmation, token);

  Future<List<Map<String, dynamic>>> getFosterMergeSuggestions(
    String orgId,
    String email,
    String token,
  ) => fosterParentsRemote.getFosterMergeSuggestions(orgId, email, token);

  Future<Map<String, dynamic>> mergeManualFoster(
    String orgId,
    String fosterParentId, {
    required String targetUserId,
    required String token,
  }) => fosterParentsRemote.mergeManualFoster(
    orgId,
    fosterParentId,
    targetUserId: targetUserId,
    token: token,
  );

  Future<List<Map<String, dynamic>>> getFosterRequests(
    String orgId,
    String token,
  ) => fosterRequestsRemote.getFosterRequests(orgId, token);

  Future<List<Map<String, dynamic>>> getEligibleFosterTargets(
    String orgId, {
    required List<String> petIds,
    required String token,
  }) => fosterRequestsRemote.getEligibleFosterTargets(
    orgId,
    petIds: petIds,
    token: token,
  );

  Future<Map<String, dynamic>> createFosterRequest(
    String orgId, {
    required String message,
    required List<String> petIds,
    required List<String> orgFosterParentIds,
    bool send = false,
    required String token,
  }) => fosterRequestsRemote.createFosterRequest(
    orgId,
    message: message,
    petIds: petIds,
    orgFosterParentIds: orgFosterParentIds,
    send: send,
    token: token,
  );

  Future<Map<String, dynamic>> getFosterRequestDetail(
    String orgId,
    String requestId,
    String token,
  ) => fosterRequestsRemote.getFosterRequestDetail(orgId, requestId, token);

  Future<Map<String, dynamic>> sendFosterRequest(
    String orgId,
    String requestId,
    String token,
  ) => fosterRequestsRemote.sendFosterRequest(orgId, requestId, token);

  Future<Map<String, dynamic>> respondToFosterRequest(
    String orgId,
    String requestId, {
    required String response,
    String? message,
    String? earliestAvailability,
    required String token,
  }) => fosterRequestsRemote.respondToFosterRequest(
    orgId,
    requestId,
    response: response,
    message: message,
    earliestAvailability: earliestAvailability,
    token: token,
  );

  Future<Map<String, dynamic>> getPetPlacement(
    String orgId,
    String petId,
    String token,
  ) => placementsRemote.getPetPlacement(orgId, petId, token);

  Future<List<Map<String, dynamic>>> getOrganizationPlacements(
    String orgId,
    String token, {
    Map<String, String>? filters,
  }) => placementsRemote.getOrganizationPlacements(
    orgId,
    token,
    filters: filters,
  );

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
