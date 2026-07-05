import 'dart:typed_data';

import '../../../../core/utils/calendar_date.dart';
import '../../domain/entities/archived_pet.dart';
import '../../domain/entities/foster_parent.dart';
import '../../domain/entities/foster_placement.dart';
import '../../domain/entities/org_person.dart';
import '../../domain/entities/organization.dart';
import '../../domain/entities/organization_member.dart';
import '../../domain/repositories/organization_repository.dart';
import '../datasources/organization_remote_datasource.dart';
import '../models/organization_model.dart';

class OrganizationRepositoryImpl implements OrganizationRepository {
  OrganizationRepositoryImpl(this._dataSource);

  final OrganizationRemoteDataSource _dataSource;

  @override
  Future<List<Organization>> getOrganizations(String token) async {
    return await _dataSource.getOrganizations(token);
  }

  @override
  Future<Organization> getOrganization(String id, String token) async {
    return await _dataSource.getOrganization(id, token);
  }

  @override
  Future<Organization> createOrganization(Organization org, String token) async {
    final model = OrganizationModel.fromEntity(org);
    return await _dataSource.createOrganization(model.toJson(), token);
  }

  @override
  Future<Organization> updateOrganization(Organization org, String token) async {
    final model = OrganizationModel.fromEntity(org);
    return await _dataSource.updateOrganization(org.id, model.toJson(), token);
  }

  @override
  Future<void> deleteOrganization(String id, String token) async {
    await _dataSource.deleteOrganization(id, token);
  }

  @override
  Future<Organization> uploadPhoto(
      String id, Uint8List bytes, String filename, String token) async {
    return await _dataSource.uploadPhoto(id, bytes, filename, token);
  }

  @override
  Future<List<OrganizationMember>> getMembers(String orgId, String token) async {
    return await _dataSource.getMembers(orgId, token);
  }

  @override
  Future<Map<String, dynamic>> inviteByEmail(
      String orgId, String email, String role, String token) async {
    return await _dataSource.inviteByEmail(orgId, email, role, token);
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingInvites(String token) async {
    return await _dataSource.getPendingInvites(token);
  }

  @override
  Future<Map<String, dynamic>> acceptInvite(String inviteId, String token) async {
    return await _dataSource.acceptInvite(inviteId, token);
  }

  @override
  Future<void> declineInvite(String inviteId, String token) async {
    await _dataSource.declineInvite(inviteId, token);
  }

  @override
  Future<void> updateMemberRole(
      String orgId, String userId, OrgMemberRole role, String token) async {
    await _dataSource.updateMemberRole(orgId, userId, role.toWire(), token);
  }

  @override
  Future<void> removeMember(String orgId, String userId, String token) async {
    await _dataSource.removeMember(orgId, userId, token);
  }

  @override
  Future<void> leaveOrganization(String orgId, String token) async {
    await _dataSource.leaveOrganization(orgId, token);
  }

  @override
  Future<List<Map<String, dynamic>>> getOrganizationPets(
      String orgId, String token) async {
    return await _dataSource.getOrganizationPets(orgId, token);
  }

  @override
  Future<Map<String, dynamic>> createOrganizationPet(
      String orgId, Map<String, dynamic> petJson, String token) async {
    return await _dataSource.createOrganizationPet(orgId, petJson, token);
  }

  @override
  Future<void> transferPetToUser(
      String orgId, String petId, {required String recipientEmail, String transferType = 'adoption', String notes = '', required String token}) async {
    await _dataSource.transferPetToUser(
      orgId,
      petId,
      recipientEmail: recipientEmail,
      transferType: transferType,
      notes: notes,
      token: token,
    );
  }

  @override
  Future<void> transferPetToOrg(
      String petId, String orgId, {String notes = '', required String token}) async {
    await _dataSource.transferPetToOrg(
      petId,
      orgId,
      notes: notes,
      token: token,
    );
  }

  @override
  Future<List<ArchivedPet>> getOrganizationArchivedPets(
      String orgId, String token) async {
    return await _dataSource.getOrganizationArchivedPets(orgId, token);
  }

  @override
  Future<List<ArchivedPet>> getUserArchivedPets(String token) async {
    return await _dataSource.getUserArchivedPets(token);
  }

  @override
  Future<List<Map<String, dynamic>>> getFamilyEvents(
      String token, String petId) async {
    return await _dataSource.getFamilyEvents(token, petId);
  }

  @override
  Future<Map<String, dynamic>> createFamilyEvent(
      String token, String petId, Map<String, dynamic> body) async {
    return await _dataSource.createFamilyEvent(token, petId, body);
  }

  @override
  Future<void> updateFamilyEvent(
      String token, String petId, String eventId, Map<String, dynamic> body) async {
    await _dataSource.updateFamilyEvent(token, petId, eventId, body);
  }

  @override
  Future<void> deleteFamilyEvent(
      String token, String petId, String eventId) async {
    await _dataSource.deleteFamilyEvent(token, petId, eventId);
  }

  @override
  Future<List<FosterParent>> getFosterParents(String orgId, String token) async {
    final rows = await _dataSource.getFosterParents(orgId, token);
    return rows.map(FosterParent.fromJson).toList();
  }

  @override
  Future<List<OrgPersonSummary>> getPeople(String orgId, String token) async {
    final rows = await _dataSource.getPeople(orgId, token);
    return rows.map(OrgPersonSummary.fromJson).toList();
  }

  @override
  Future<OrgPersonDetail> getPersonDetail(
    String orgId,
    OrgPersonKind kind,
    String recordId,
    String token,
  ) async {
    final row = await _dataSource.getPersonDetail(
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
    final row = await _dataSource.updatePersonContact(
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
    final row = await _dataSource.createExternalFosterParent(
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
    final row = await _dataSource.updateExternalFosterParent(
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
      String orgId, String fosterParentId, String token) async {
    await _dataSource.deleteExternalFosterParent(orgId, fosterParentId, token);
  }

  @override
  Future<PetFosterPlacementState> getPetPlacement(
      String orgId, String petId, String token) async {
    final row = await _dataSource.getPetPlacement(orgId, petId, token);
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
    final row = await _dataSource.startFosterPlacement(
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
    final row = await _dataSource.endFosterPlacement(
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
    final row = await _dataSource.startAdoption(
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
    final row = await _dataSource.completeAdoptionConditions(
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
    final row = await _dataSource.cancelAdoption(
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
    final row = await _dataSource.directAdopt(
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
    final rows = await _dataSource.getPetFosterHistory(orgId, petId, token);
    return rows.map(FosterPlacement.fromJson).toList();
  }
}
