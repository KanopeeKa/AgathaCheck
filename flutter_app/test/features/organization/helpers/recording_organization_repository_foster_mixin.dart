import 'package:pet_profile_app/features/organization/domain/entities/foster_parent.dart';
import 'package:pet_profile_app/features/organization/domain/entities/foster_request.dart';
import 'package:pet_profile_app/features/organization/domain/entities/org_person.dart';

import 'recording_organization_repository_base.dart';

mixin RecordingOrganizationRepositoryFosterMixin
    on RecordingOrganizationRepositoryBase {
  @override
  Future<List<FosterParent>> getFosterParents(
    String orgId,
    String token,
  ) async => [];

  @override
  Future<List<OrgPersonSummary>> getPeople(String orgId, String token) async =>
      [];

  @override
  Future<OrgPersonDetail> getPersonDetail(
    String orgId,
    OrgPersonKind kind,
    String recordId,
    String token,
  ) async => OrgPersonDetail(
    id: 'member:$recordId',
    kind: kind,
    recordId: recordId,
    displayName: 'Test',
  );

  @override
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
  }) async => OrgPersonDetail(
    id: '${kind.wire}:$recordId',
    kind: kind,
    recordId: recordId,
    displayName: displayName ?? 'Test',
    fosterPhone: fosterPhone ?? '',
    fosterAddress: fosterAddress ?? '',
    adminNotes: adminNotes ?? '',
  );

  @override
  Future<FosterParent> createExternalFosterParent(
    String orgId, {
    required String displayName,
    required String email,
    String? phone,
    String fosterAddress = '',
    String notes = '',
    required bool lawfulBasisConfirmed,
    required String token,
  }) async => FosterParent(
    id: 'fp-1',
    kind: FosterParentKind.external,
    displayName: displayName,
    email: email,
  );

  @override
  Future<FosterParent> updateExternalFosterParent(
    String orgId,
    String fosterParentId, {
    required String displayName,
    String? email,
    String? phone,
    String notes = '',
    required String token,
  }) async => FosterParent(
    id: fosterParentId,
    kind: FosterParentKind.external,
    displayName: displayName,
  );

  @override
  Future<void> deleteExternalFosterParent(
    String orgId,
    String fosterParentId,
    String token,
  ) async {}

  @override
  Future<FosterParent> updateFosterApproval(
    String orgId,
    String fosterParentId,
    FosterApprovalState approvalState, {
    required String token,
  }) async => FosterParent(
    id: fosterParentId,
    kind: FosterParentKind.external,
    displayName: 'Updated',
    approvalState: approvalState,
  );

  @override
  Future<List<FosterMergeSuggestion>> getFosterMergeSuggestions(
    String orgId,
    String email, {
    required String token,
  }) async => [
    FosterMergeSuggestion(
      userId: 'registered-user-1',
      displayName: 'Registered User',
      email: email,
      fosterProfileId: 'fprof-1',
    ),
  ];

  @override
  Future<FosterParent> mergeManualFoster(
    String orgId,
    String fosterParentId, {
    required String targetUserId,
    required String token,
  }) async => FosterParent(
    id: fosterParentId,
    kind: FosterParentKind.external,
    userId: targetUserId,
    fosterProfileId: 'fprof-1',
    displayName: 'Merged Parent',
    email: 'merged@example.com',
  );

  @override
  Future<FosterParent> updateFosterOptOut(
    String orgId,
    String fosterParentId,
    bool optOut, {
    required String token,
  }) async => FosterParent(
    id: fosterParentId,
    kind: FosterParentKind.external,
    displayName: 'Updated',
    optOutAt: optOut ? DateTime.utc(2026, 7, 25) : null,
  );

  @override
  Future<FosterParent> updateFosterRetentionCategory(
    String orgId,
    String fosterParentId,
    String retentionCategory, {
    required String token,
  }) async => FosterParent(
    id: fosterParentId,
    kind: FosterParentKind.external,
    displayName: 'Updated',
    retentionCategory: retentionCategory,
  );

  @override
  Future<List<FosterRequest>> getFosterRequests(
    String orgId,
    String token,
  ) async => [];

  @override
  Future<List<String>> getEligibleFosterTargetIds(
    String orgId, {
    required List<String> petIds,
    required String token,
  }) async => [];

  @override
  Future<List<Map<String, dynamic>>> getProspects(
    String orgId,
    String token,
  ) async => [];

  @override
  Future<List<Map<String, dynamic>>> getAdoptionVisits(
    String orgId,
    String token,
  ) async => [];

  @override
  Future<Map<String, dynamic>> getAdoptionJourney(
    String orgId,
    String placementId,
    String token,
  ) async => {};

  @override
  Future<Map<String, dynamic>> getSessionChecklist(
    String orgId,
    String placementId,
    String token,
  ) async => {'items': []};

  @override
  Future<Map<String, dynamic>> updateSessionChecklistItem(
    String orgId,
    String placementId,
    String itemKey, {
    required bool completed,
    required String token,
  }) async => {'items': []};

  @override
  Future<Map<String, dynamic>> getAdoptionMilestones(
    String orgId,
    String placementId,
    String token,
  ) async => {'journey_id': 'journey-1', 'items': []};

  @override
  Future<Map<String, dynamic>> updateAdoptionMilestoneItem(
    String orgId,
    String journeyId,
    String itemKey, {
    required bool completed,
    required String token,
  }) async => {'items': []};

  @override
  Future<Map<String, dynamic>> getRegisterExport(
    String orgId,
    String placementId,
    String token,
  ) async => {'format': 'markdown', 'content': '# Register export'};

  @override
  Future<FosterRequest> createFosterRequest(
    String orgId, {
    required String message,
    required List<String> petIds,
    required List<String> orgFosterParentIds,
    bool send = false,
    required String token,
  }) async => FosterRequest(
    id: 'fr-new',
    organizationId: orgId,
    message: message,
    status: send ? FosterRequestStatus.sent : FosterRequestStatus.draft,
    petIds: petIds,
    pets: petIds
        .map((id) => FosterRequestPet(petId: id, petName: 'Pet $id'))
        .toList(),
    targetCount: orgFosterParentIds.length,
  );

  @override
  Future<FosterRequest> getFosterRequestDetail(
    String orgId,
    String requestId,
    String token,
  ) async => FosterRequest(
    id: requestId,
    organizationId: orgId,
    message: 'Test request',
    status: FosterRequestStatus.sent,
  );

  @override
  Future<FosterRequest> sendFosterRequest(
    String orgId,
    String requestId, {
    required String token,
  }) async => FosterRequest(
    id: requestId,
    organizationId: orgId,
    message: 'Test request',
    status: FosterRequestStatus.sent,
  );

  @override
  Future<FosterRequest> respondToFosterRequest(
    String orgId,
    String requestId, {
    required FosterResponseType response,
    String? message,
    DateTime? earliestAvailability,
    required String token,
  }) async => FosterRequest(
    id: requestId,
    organizationId: orgId,
    message: 'Test request',
    status: FosterRequestStatus.sent,
    responses: [
      FosterRequestResponse(
        id: 'frr-1',
        orgFosterParentId: 'fp-1',
        response: response,
        message: message ?? '',
        earliestAvailability: earliestAvailability,
      ),
    ],
  );
}
