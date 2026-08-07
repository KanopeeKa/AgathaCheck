import '../../domain/entities/foster_onboarding_step.dart';
import '../../domain/entities/foster_parent.dart';
import '../../domain/entities/foster_self_prefs.dart';
import '../../domain/entities/org_person.dart';
import 'organization_repository_impl_base.dart';

mixin OrganizationRepositoryFosterParentsMixin
    on OrganizationRepositoryImplBase {
  @override
  Future<List<FosterParent>> getFosterParents(
    String orgId,
    String token,
  ) async {
    final rows = await dataSource.getFosterParents(orgId, token);
    return rows.map(FosterParent.fromJson).toList();
  }

  @override
  Future<List<OrgPersonSummary>> getPeople(String orgId, String token) async {
    final rows = await dataSource.getPeople(orgId, token);
    return rows.map(OrgPersonSummary.fromJson).toList();
  }

  @override
  Future<OrgPersonDetail> getPersonDetail(
    String orgId,
    OrgPersonKind kind,
    String recordId,
    String token,
  ) async {
    final row = await dataSource.getPersonDetail(
      orgId,
      kind.wire,
      recordId,
      token,
    );
    return OrgPersonDetail.fromJson(row);
  }

  @override
  Future<FosterOnboardingStatus> confirmFosterOnboardingStep(
    String orgId,
    OrgPersonKind kind,
    String recordId,
    String stepKey, {
    required String token,
  }) async {
    final row = await dataSource.confirmFosterOnboardingStep(
      orgId,
      kind.wire,
      recordId,
      stepKey,
      token,
    );
    return FosterOnboardingStatus.fromJson(row);
  }

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
  }) async {
    final body = <String, dynamic>{
      if (fosterPhone != null) 'foster_phone': fosterPhone,
      if (fosterAddress != null) 'foster_address': fosterAddress,
      if (adminNotes != null) 'admin_notes': adminNotes,
      if (displayName != null) 'display_name': displayName,
      if (email != null) 'email': email,
    };
    final row = await dataSource.updatePersonContact(
      orgId,
      kind.wire,
      recordId,
      body,
      token,
    );
    return OrgPersonDetail.fromJson(row);
  }

  @override
  Future<Map<String, dynamic>> fosterInvite(
    String orgId, {
    String? email,
    List<String>? userIds,
    required String token,
  }) => dataSource.fosterInvite(
    orgId,
    email: email,
    userIds: userIds,
    token: token,
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
  }) async {
    final row = await dataSource.createExternalFosterParent(
      orgId,
      displayName: displayName,
      email: email,
      phone: phone,
      fosterAddress: fosterAddress,
      notes: notes,
      lawfulBasisConfirmed: lawfulBasisConfirmed,
      token: token,
    );
    return FosterParent.fromJson(row);
  }

  @override
  Future<FosterParent> updateExternalFosterParent(
    String orgId,
    String fosterParentId, {
    required String displayName,
    String? email,
    String? phone,
    String notes = '',
    required String token,
  }) async {
    final row = await dataSource.updateExternalFosterParent(
      orgId,
      fosterParentId,
      displayName: displayName,
      email: email,
      phone: phone,
      notes: notes,
      token: token,
    );
    return FosterParent.fromJson(row);
  }

  @override
  Future<void> deleteExternalFosterParent(
    String orgId,
    String fosterParentId,
    String token,
  ) async {
    await dataSource.deleteExternalFosterParent(orgId, fosterParentId, token);
  }

  @override
  Future<FosterParent> updateFosterApproval(
    String orgId,
    String fosterParentId,
    FosterApprovalState approvalState, {
    required String token,
  }) async {
    final row = await dataSource.updateFosterApproval(
      orgId,
      fosterParentId,
      approvalState.toWire(),
      token,
    );
    return FosterParent.fromJson(row);
  }

  @override
  Future<FosterParent> updateFosterOptOut(
    String orgId,
    String fosterParentId,
    bool optOut, {
    required String token,
  }) async {
    final row = await dataSource.updateFosterOptOut(
      orgId,
      fosterParentId,
      optOut,
      token,
    );
    return FosterParent.fromJson(row);
  }

  @override
  Future<FosterParent> updateFosterRetentionCategory(
    String orgId,
    String fosterParentId,
    String retentionCategory, {
    required String token,
  }) async {
    final row = await dataSource.updateFosterRetentionCategory(
      orgId,
      fosterParentId,
      retentionCategory,
      token,
    );
    return FosterParent.fromJson(row);
  }

  @override
  Future<List<FosterMergeSuggestion>> getFosterMergeSuggestions(
    String orgId,
    String email, {
    required String token,
  }) async {
    final rows = await dataSource.getFosterMergeSuggestions(
      orgId,
      email,
      token,
    );
    return rows.map(FosterMergeSuggestion.fromJson).toList();
  }

  @override
  Future<FosterParent> mergeManualFoster(
    String orgId,
    String fosterParentId, {
    required String targetUserId,
    required String token,
  }) async {
    final row = await dataSource.mergeManualFoster(
      orgId,
      fosterParentId,
      targetUserId: targetUserId,
      token: token,
    );
    return FosterParent.fromJson(row);
  }

  @override
  Future<FosterSelfPrefs> updateFosterSelfVisibility(
    String orgId,
    FosterSelfPrefs prefs, {
    required String token,
  }) async {
    final row = await dataSource.updateFosterSelfVisibility(
      orgId,
      prefs.toJson(),
      token,
    );
    return FosterSelfPrefs.fromJson(row);
  }

  @override
  Future<void> withdrawFosterAgreement(
    String orgId,
    String confirmation, {
    required String token,
  }) async {
    await dataSource.withdrawFosterAgreement(orgId, confirmation, token);
  }
}
