import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/foster_parent.dart';
import '../../domain/entities/foster_self_prefs.dart';
import '../../domain/entities/org_person.dart';
import '../../domain/entities/organization_member.dart';
import 'org_provider_deps.dart';

class OrgMembersNotifier
    extends FamilyAsyncNotifier<List<OrganizationMember>, String> {
  @override
  Future<List<OrganizationMember>> build(String orgId) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) return [];
    final repo = ref.read(organizationRepositoryProvider);
    return repo.getMembers(orgId, token);
  }

  Future<void> inviteByEmail(String email, String role) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.inviteByEmail(arg, email, role, token);
    ref.invalidateSelf();
  }

  Future<void> updateMemberRole(String userId, String role) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.updateMemberRole(
      arg,
      userId,
      OrgMemberRole.fromWire(role),
      token,
    );
    ref.invalidateSelf();
  }

  Future<void> removeMember(String userId) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.removeMember(arg, userId, token);
    ref.invalidateSelf();
  }

  Future<void> leaveOrganization() async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.leaveOrganization(arg, token);
  }
}

final orgMembersProvider =
    AsyncNotifierProvider.family<
      OrgMembersNotifier,
      List<OrganizationMember>,
      String
    >(OrgMembersNotifier.new);

class OrgPeopleNotifier
    extends FamilyAsyncNotifier<List<OrgPersonSummary>, String> {
  @override
  Future<List<OrgPersonSummary>> build(String orgId) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) return [];
    final repo = ref.read(organizationRepositoryProvider);
    return repo.getPeople(orgId, token);
  }

  Future<void> createExternal({
    required String displayName,
    required String email,
    String? phone,
    String fosterAddress = '',
    String notes = '',
    required bool lawfulBasisConfirmed,
  }) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.createExternalFosterParent(
      arg,
      displayName: displayName,
      email: email,
      phone: phone,
      fosterAddress: fosterAddress,
      notes: notes,
      lawfulBasisConfirmed: lawfulBasisConfirmed,
      token: token,
    );
    ref.invalidateSelf();
    ref.invalidate(orgFosterParentsProvider(arg));
  }

  Future<void> deleteExternal(String recordId) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.deleteExternalFosterParent(arg, recordId, token);
    ref.invalidateSelf();
  }

  Future<Map<String, dynamic>> onboardAsFoster({
    String? email,
    List<String>? userIds,
  }) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    final result = await repo.fosterInvite(
      arg,
      email: email,
      userIds: userIds,
      token: token,
    );
    ref.invalidateSelf();
    ref.invalidate(orgFosterParentsProvider(arg));
    return result;
  }
}

final orgPeopleProvider =
    AsyncNotifierProvider.family<
      OrgPeopleNotifier,
      List<OrgPersonSummary>,
      String
    >(OrgPeopleNotifier.new);

typedef OrgPersonDetailKey = ({
  String orgId,
  OrgPersonKind kind,
  String recordId,
});

class OrgPersonDetailNotifier
    extends FamilyAsyncNotifier<OrgPersonDetail, OrgPersonDetailKey> {
  @override
  Future<OrgPersonDetail> build(OrgPersonDetailKey key) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) {
      throw StateError('Not authenticated');
    }
    final repo = ref.read(organizationRepositoryProvider);
    return repo.getPersonDetail(key.orgId, key.kind, key.recordId, token);
  }

  Future<void> confirmFosterOnboardingStep(String stepKey) async {
    final token = ref.read(orgTokenProvider)!;
    final timeline = await ref.read(organizationRepositoryProvider).confirmFosterOnboardingStep(
      arg.orgId, arg.kind, arg.recordId, stepKey, token: token);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(OrgPersonDetail(
        id: current.id, kind: current.kind, recordId: current.recordId, userId: current.userId,
        displayName: current.displayName, email: current.email, role: current.role,
        photoUrl: current.photoUrl, isPending: current.isPending,
        activeFosterCount: current.activeFosterCount, categoryRank: current.categoryRank,
        fosterApprovalState: current.fosterApprovalState, fosterNeedsAttention: current.fosterNeedsAttention,
        fosterPhone: current.fosterPhone, fosterAddress: current.fosterAddress, adminNotes: current.adminNotes,
        currentPlacements: current.currentPlacements, pastPlacements: current.pastPlacements,
        fosterOnboarding: timeline,
      ));
    } else {
      ref.invalidateSelf();
    }
  }

  Future<void> updateContact({
    String? fosterPhone,
    String? fosterAddress,
    String? adminNotes,
    String? displayName,
    String? email,
  }) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.updatePersonContact(
      arg.orgId,
      arg.kind,
      arg.recordId,
      fosterPhone: fosterPhone,
      fosterAddress: fosterAddress,
      adminNotes: adminNotes,
      displayName: displayName,
      email: email,
      token: token,
    );
    ref.invalidateSelf();
    ref.invalidate(orgPeopleProvider(arg.orgId));
  }

  Future<void> updateMemberRole(String userId, String role) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.updateMemberRole(
      arg.orgId,
      userId,
      OrgMemberRole.fromWire(role),
      token,
    );
    ref.invalidateSelf();
    ref.invalidate(orgPeopleProvider(arg.orgId));
    ref.invalidate(orgMembersProvider(arg.orgId));
  }

  Future<void> removeMember(String userId) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.removeMember(arg.orgId, userId, token);
    ref.invalidate(orgPeopleProvider(arg.orgId));
    ref.invalidate(orgMembersProvider(arg.orgId));
  }
}

final orgPersonDetailProvider =
    AsyncNotifierProvider.family<
      OrgPersonDetailNotifier,
      OrgPersonDetail,
      OrgPersonDetailKey
    >(OrgPersonDetailNotifier.new);

class OrgFosterParentsNotifier
    extends FamilyAsyncNotifier<List<FosterParent>, String> {
  @override
  Future<List<FosterParent>> build(String orgId) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) return [];
    final repo = ref.read(organizationRepositoryProvider);
    return repo.getFosterParents(orgId, token);
  }

  Future<void> createExternal({
    required String displayName,
    required String email,
    String? phone,
    String fosterAddress = '',
    String notes = '',
    required bool lawfulBasisConfirmed,
  }) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.createExternalFosterParent(
      arg,
      displayName: displayName,
      email: email,
      phone: phone,
      fosterAddress: fosterAddress,
      notes: notes,
      lawfulBasisConfirmed: lawfulBasisConfirmed,
      token: token,
    );
    ref.invalidateSelf();
    ref.invalidate(orgPeopleProvider(arg));
  }

  Future<void> deleteExternal(String fosterParentId) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.deleteExternalFosterParent(arg, fosterParentId, token);
    ref.invalidateSelf();
  }

  Future<void> updateApproval(
    String fosterParentId,
    FosterApprovalState approvalState,
  ) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.updateFosterApproval(
      arg,
      fosterParentId,
      approvalState,
      token: token,
    );
    ref.invalidateSelf();
    ref.invalidate(orgPeopleProvider(arg));
  }

  Future<List<FosterMergeSuggestion>> fetchMergeSuggestions(
    String email,
  ) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    return repo.getFosterMergeSuggestions(arg, email, token: token);
  }

  Future<void> mergeIntoRegisteredAccount({
    required String fosterParentId,
    required String targetUserId,
  }) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.mergeManualFoster(
      arg,
      fosterParentId,
      targetUserId: targetUserId,
      token: token,
    );
    ref.invalidateSelf();
    ref.invalidate(orgPeopleProvider(arg));
  }

  Future<void> updateOptOut(String fosterParentId, bool optOut) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.updateFosterOptOut(arg, fosterParentId, optOut, token: token);
    ref.invalidateSelf();
  }

  Future<void> updateSelfVisibility(FosterSelfPrefs prefs) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.updateFosterSelfVisibility(arg, prefs, token: token);
    ref.invalidateSelf();
  }

  Future<void> withdrawAgreement(String confirmation) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.withdrawFosterAgreement(arg, confirmation, token: token);
    ref.invalidateSelf();
  }
}

final orgFosterParentsProvider =
    AsyncNotifierProvider.family<
      OrgFosterParentsNotifier,
      List<FosterParent>,
      String
    >(OrgFosterParentsNotifier.new);
