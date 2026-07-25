import '../../../../core/utils/calendar_date.dart';
import '../../domain/entities/foster_parent.dart';
import '../../domain/entities/foster_placement.dart';
import '../../domain/entities/org_person.dart';
import 'organization_repository_impl_base.dart';

mixin OrganizationRepositoryFosterMixin on OrganizationRepositoryImplBase {
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
}
