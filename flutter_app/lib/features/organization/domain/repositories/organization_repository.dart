import 'dart:typed_data';

import '../entities/archived_pet.dart';
import '../entities/custody_transfer.dart';
import '../entities/foster_parent.dart';
import '../entities/foster_self_prefs.dart';
import '../entities/foster_placement.dart';
import '../entities/foster_request.dart';
import '../entities/org_connection.dart';
import '../entities/org_home_hidden_pet.dart';
import '../entities/org_person.dart';
import '../entities/organization.dart';
import '../entities/organization_member.dart';

abstract class OrganizationRepository {
  Future<List<Organization>> getOrganizations(String token);
  Future<Organization> getOrganization(String id, String token);
  Future<Organization> createOrganization(Organization org, String token);
  Future<Organization> updateOrganization(Organization org, String token);
  Future<void> deleteOrganization(String id, String token);
  Future<Organization> uploadPhoto(
    String id,
    Uint8List bytes,
    String filename,
    String token,
  );
  Future<Organization> uploadLogo(
    String id,
    Uint8List bytes,
    String filename,
    String token,
  );
  Future<Organization> setPrimaryContact(
    String orgId,
    String recordId,
    String token,
  );

  Future<List<OrganizationMember>> getMembers(String orgId, String token);
  Future<Map<String, dynamic>> inviteByEmail(
    String orgId,
    String email,
    String role,
    String token,
  );
  Future<void> updateMemberRole(
    String orgId,
    String userId,
    OrgMemberRole role,
    String token,
  );
  Future<void> removeMember(String orgId, String userId, String token);
  Future<void> leaveOrganization(String orgId, String token);

  // Invites the authenticated user has received.
  Future<List<Map<String, dynamic>>> getPendingInvites(String token);
  Future<Map<String, dynamic>> acceptInvite(String inviteId, String token);
  Future<void> declineInvite(String inviteId, String token);

  Future<List<Map<String, dynamic>>> getOrganizationPets(
    String orgId,
    String token,
  );
  Future<Map<String, dynamic>> createOrganizationPet(
    String orgId,
    Map<String, dynamic> petJson,
    String token,
  );
  Future<void> transferPetToUser(
    String orgId,
    String petId, {
    required String recipientEmail,
    String transferType,
    String notes,
    required String token,
  });
  Future<void> transferPetToOrg(
    String petId,
    String orgId, {
    String notes,
    required String token,
  });

  Future<List<ArchivedPet>> getOrganizationArchivedPets(
    String orgId,
    String token,
  );
  Future<List<ArchivedPet>> getUserArchivedPets(String token);

  // Per-pet family events (raw maps, mirroring getOrganizationPets).
  Future<List<Map<String, dynamic>>> getFamilyEvents(
    String token,
    String petId,
  );
  Future<Map<String, dynamic>> createFamilyEvent(
    String token,
    String petId,
    Map<String, dynamic> body,
  );
  Future<void> updateFamilyEvent(
    String token,
    String petId,
    String eventId,
    Map<String, dynamic> body,
  );
  Future<void> deleteFamilyEvent(String token, String petId, String eventId);

  Future<List<FosterParent>> getFosterParents(String orgId, String token);
  Future<List<OrgPersonSummary>> getPeople(String orgId, String token);
  Future<OrgPersonDetail> getPersonDetail(
    String orgId,
    OrgPersonKind kind,
    String recordId,
    String token,
  );
  Future<OrgPersonDetail> updatePersonContact(
    String orgId,
    OrgPersonKind kind,
    String recordId, {
    String? fosterPhone,
    String? fosterAddress,
    String? adminNotes,
    String? displayName,
    String? email,
    required String token,
  });
  Future<FosterParent> createExternalFosterParent(
    String orgId, {
    required String displayName,
    required String email,
    String? phone,
    String fosterAddress = '',
    String notes = '',
    required bool lawfulBasisConfirmed,
    required String token,
  });
  Future<FosterParent> updateExternalFosterParent(
    String orgId,
    String fosterParentId, {
    required String displayName,
    String? email,
    String? phone,
    String notes,
    required String token,
  });
  Future<void> deleteExternalFosterParent(
    String orgId,
    String fosterParentId,
    String token,
  );
  Future<FosterParent> updateFosterApproval(
    String orgId,
    String fosterParentId,
    FosterApprovalState approvalState, {
    required String token,
  });
  Future<FosterParent> updateFosterOptOut(
    String orgId,
    String fosterParentId,
    bool optOut, {
    required String token,
  });
  Future<FosterParent> updateFosterRetentionCategory(
    String orgId,
    String fosterParentId,
    String retentionCategory, {
    required String token,
  });
  Future<List<FosterMergeSuggestion>> getFosterMergeSuggestions(
    String orgId,
    String email, {
    required String token,
  });
  Future<FosterParent> mergeManualFoster(
    String orgId,
    String fosterParentId, {
    required String targetUserId,
    required String token,
  });

  Future<FosterSelfPrefs> updateFosterSelfVisibility(
    String orgId,
    FosterSelfPrefs prefs, {
    required String token,
  });

  Future<void> withdrawFosterAgreement(
    String orgId,
    String confirmation, {
    required String token,
  });

  Future<List<FosterRequest>> getFosterRequests(String orgId, String token);
  Future<List<String>> getEligibleFosterTargetIds(
    String orgId, {
    required List<String> petIds,
    required String token,
  });
  Future<FosterRequest> createFosterRequest(
    String orgId, {
    required String message,
    required List<String> petIds,
    required List<String> orgFosterParentIds,
    bool send,
    required String token,
  });
  Future<FosterRequest> getFosterRequestDetail(
    String orgId,
    String requestId,
    String token,
  );
  Future<FosterRequest> sendFosterRequest(
    String orgId,
    String requestId, {
    required String token,
  });
  Future<FosterRequest> respondToFosterRequest(
    String orgId,
    String requestId, {
    required FosterResponseType response,
    String? message,
    DateTime? earliestAvailability,
    required String token,
  });

  Future<List<FosterPlacement>> getOrganizationPlacements(
    String orgId,
    String token,
  );
  Future<PetFosterPlacementState> getPetPlacement(
    String orgId,
    String petId,
    String token,
  );
  Future<FosterPlacement> startFosterPlacement(
    String orgId,
    String petId, {
    required String fosterUserId,
    DateTime? startDate,
    String notes,
    required String token,
  });
  Future<FosterPlacement> endFosterPlacement(
    String orgId,
    String placementId, {
    DateTime? endDate,
    required String token,
  });
  Future<FosterPlacement> startAdoption(
    String orgId,
    String placementId, {
    String adoptionConditions = '',
    required String token,
  });
  Future<FosterPlacement> completeAdoptionConditions(
    String orgId,
    String placementId, {
    required String token,
  });
  Future<FosterPlacement> cancelAdoption(
    String orgId,
    String placementId, {
    DateTime? endDate,
    required String token,
  });
  Future<FosterPlacement> directAdopt(
    String orgId,
    String petId, {
    required String fosterUserId,
    String adoptionConditions = '',
    String notes = '',
    required String token,
  });
  Future<List<FosterPlacement>> getPetFosterHistory(
    String orgId,
    String petId,
    String token,
  );

  Future<FosterPlacement> getPlacementDetail(
    String orgId,
    String placementId,
    String token,
  );
  Future<FosterPlacement> transitionFosteringSession(
    String orgId,
    String placementId, {
    required String sessionStatus,
    required String token,
  });
  Future<FosterPlacement> confirmShelterSessionStart(
    String orgId,
    String placementId, {
    required String token,
  });
  Future<FosterPlacement> confirmFosterSessionStart(
    String orgId,
    String placementId, {
    required String token,
  });
  Future<FosterPlacement> requestFosteringSessionEnd(
    String orgId,
    String placementId, {
    required String token,
  });
  Future<FosterPlacement> endFosteringSession(
    String orgId,
    String placementId, {
    required String outcome,
    DateTime? endDate,
    required String token,
  });

  Future<List<Map<String, dynamic>>> getProspects(String orgId, String token);
  Future<List<Map<String, dynamic>>> getAdoptionVisits(
    String orgId,
    String token,
  );
  Future<Map<String, dynamic>> getAdoptionJourney(
    String orgId,
    String placementId,
    String token,
  );
  Future<Map<String, dynamic>> getSessionChecklist(
    String orgId,
    String placementId,
    String token,
  );
  Future<Map<String, dynamic>> updateSessionChecklistItem(
    String orgId,
    String placementId,
    String itemKey, {
    required bool completed,
    required String token,
  });
  Future<Map<String, dynamic>> getAdoptionMilestones(
    String orgId,
    String placementId,
    String token,
  );
  Future<Map<String, dynamic>> updateAdoptionMilestoneItem(
    String orgId,
    String journeyId,
    String itemKey, {
    required bool completed,
    required String token,
  });
  Future<Map<String, dynamic>> getRegisterExport(
    String orgId,
    String placementId,
    String token,
  );
  Future<Map<String, dynamic>> recordAdoptionVisitOutcome(
    String orgId,
    String visitId,
    String visitOutcome,
    String token,
  );
  Future<Map<String, dynamic>> completeVisitAndStartAdoption(
    String orgId,
    String placementId, {
    String? visitId,
    String adoptionConditions = '',
    required String token,
  });

  Future<List<OrgConnection>> getConnections(String orgId, String token);

  Future<Map<String, dynamic>> createConnectionRequest(
    String orgId, {
    required String targetOrgId,
    required String token,
  });

  Future<List<OrgConnectionRequest>> getConnectionRequests(
    String orgId,
    String token,
  );

  Future<void> revokeConnectionRequest(
    String orgId,
    String requestId,
    String token,
  );

  Future<void> acceptConnectionRequest(String token, String requestToken);

  Future<void> disconnectOrgs(String orgId, String otherOrgId, String token);

  Future<Map<String, dynamic>> requestCustodyTransfer(
    String orgId,
    String petId, {
    required String transferKind,
    String? toOrgId,
    String? toUserId,
    String notes = '',
    required String token,
  });

  Future<List<CustodyTransfer>> getPendingCustodyTransfers(String token);

  Future<void> acceptCustodyTransfer(String transferId, String token);

  Future<void> cancelCustodyTransfer(
    String transferId,
    String token, {
    String reason = '',
  });

  Future<void> setPetHomeHidden(
    String orgId,
    String petId, {
    required bool hidden,
    required String token,
  });

  Future<List<OrgHomeHiddenPet>> getHomeHiddenPets(String orgId, String token);

  Future<Map<String, dynamic>> getPermissionBundles(String orgId, String token);
  Future<Map<String, dynamic>> getMemberPermissions(
    String orgId,
    String targetUserId,
    String token,
  );
  Future<Map<String, dynamic>> applyPermissionBundle(
    String orgId,
    String targetUserId,
    String preset,
    String token,
  );
  Future<Map<String, dynamic>> grantMemberPermission(
    String orgId,
    String targetUserId,
    String permissionKey,
    String token,
  );
  Future<Map<String, dynamic>> revokeMemberPermission(
    String orgId,
    String targetUserId,
    String permissionKey,
    String token,
  );
  Future<List<Map<String, dynamic>>> getOrgAuditEvents(
    String orgId,
    String token,
  );
  Future<Map<String, dynamic>> getDocumentTemplates(String orgId, String token);
}
