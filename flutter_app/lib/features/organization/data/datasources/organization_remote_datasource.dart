import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/archived_pet_model.dart';
import '../models/organization_member_model.dart';
import '../models/organization_model.dart';
import '../../domain/entities/custody_transfer.dart';
import '../../domain/entities/org_connection.dart';
import 'organization_remote/organization_connections_remote.dart';
import 'organization_remote/organization_custody_remote.dart';
import 'organization_remote/organization_core_remote.dart';
import 'organization_remote/organization_foster_parents_remote.dart';
import 'organization_remote/organization_invites_remote.dart';
import 'organization_remote/organization_members_remote.dart';
import 'organization_remote/organization_pets_remote.dart';
import 'organization_remote/organization_placements_remote.dart';
import 'organization_remote/organization_remote_context.dart';

/// Facade over modular organization HTTP clients. Mirrors `server/routes/organizations/`.
class OrganizationRemoteDataSource {
  OrganizationRemoteDataSource({String? baseUrl, http.Client? client})
    : _ctx = OrganizationRemoteContext(baseUrl: baseUrl, client: client) {
    _core = OrganizationCoreRemote(_ctx);
    _invites = OrganizationInvitesRemote(_ctx);
    _members = OrganizationMembersRemote(_ctx);
    _pets = OrganizationPetsRemote(_ctx);
    _fosterParents = OrganizationFosterParentsRemote(_ctx);
    _placements = OrganizationPlacementsRemote(_ctx);
    _connections = OrganizationConnectionsRemote(_ctx);
    _custody = OrganizationCustodyRemote(_ctx);
  }

  final OrganizationRemoteContext _ctx;
  late final OrganizationCoreRemote _core;
  late final OrganizationInvitesRemote _invites;
  late final OrganizationMembersRemote _members;
  late final OrganizationPetsRemote _pets;
  late final OrganizationFosterParentsRemote _fosterParents;
  late final OrganizationPlacementsRemote _placements;
  late final OrganizationConnectionsRemote _connections;
  late final OrganizationCustodyRemote _custody;

  String get baseUrl => _ctx.baseUrl;

  Future<List<OrganizationModel>> getOrganizations(String token) =>
      _core.getOrganizations(token);

  Future<OrganizationModel> getOrganization(String id, String token) =>
      _core.getOrganization(id, token);

  Future<OrganizationModel> createOrganization(
    Map<String, dynamic> orgJson,
    String token,
  ) => _core.createOrganization(orgJson, token);

  Future<OrganizationModel> updateOrganization(
    String id,
    Map<String, dynamic> orgJson,
    String token,
  ) => _core.updateOrganization(id, orgJson, token);

  Future<void> deleteOrganization(String id, String token) =>
      _core.deleteOrganization(id, token);

  Future<OrganizationModel> uploadPhoto(
    String id,
    Uint8List bytes,
    String filename,
    String token,
  ) => _core.uploadPhoto(id, bytes, filename, token);

  Future<OrganizationModel> uploadLogo(
    String id,
    Uint8List bytes,
    String filename,
    String token,
  ) => _core.uploadLogo(id, bytes, filename, token);

  Future<OrganizationModel> setPrimaryContact(
    String orgId,
    String recordId,
    String token,
  ) => _core.setPrimaryContact(orgId, recordId, token);

  Future<List<OrganizationMemberModel>> getMembers(
    String orgId,
    String token,
  ) => _members.getMembers(orgId, token);

  Future<Map<String, dynamic>> inviteByEmail(
    String orgId,
    String email,
    String role,
    String token,
  ) => _members.inviteByEmail(orgId, email, role, token);

  Future<List<Map<String, dynamic>>> getPendingInvites(String token) =>
      _invites.getPendingInvites(token);

  Future<Map<String, dynamic>> acceptInvite(String inviteId, String token) =>
      _invites.acceptInvite(inviteId, token);

  Future<void> declineInvite(String inviteId, String token) =>
      _invites.declineInvite(inviteId, token);

  Future<void> updateMemberRole(
    String orgId,
    String userId,
    String role,
    String token,
  ) => _members.updateMemberRole(orgId, userId, role, token);

  Future<void> removeMember(String orgId, String userId, String token) =>
      _members.removeMember(orgId, userId, token);

  Future<void> leaveOrganization(String orgId, String token) =>
      _members.leaveOrganization(orgId, token);

  Future<List<Map<String, dynamic>>> getOrganizationPets(
    String orgId,
    String token,
  ) => _pets.getOrganizationPets(orgId, token);

  Future<Map<String, dynamic>> createOrganizationPet(
    String orgId,
    Map<String, dynamic> petJson,
    String token,
  ) => _pets.createOrganizationPet(orgId, petJson, token);

  Future<void> transferPetToUser(
    String orgId,
    String petId, {
    required String recipientEmail,
    String transferType = 'adoption',
    String notes = '',
    required String token,
  }) => _pets.transferPetToUser(
    orgId,
    petId,
    recipientEmail: recipientEmail,
    transferType: transferType,
    notes: notes,
    token: token,
  );

  Future<void> transferPetToOrg(
    String petId,
    String orgId, {
    String transferType = 'transfer',
    String notes = '',
    required String token,
  }) => _pets.transferPetToOrg(
    petId,
    orgId,
    transferType: transferType,
    notes: notes,
    token: token,
  );

  Future<List<ArchivedPetModel>> getOrganizationArchivedPets(
    String orgId,
    String token,
  ) => _pets.getOrganizationArchivedPets(orgId, token);

  Future<List<ArchivedPetModel>> getUserArchivedPets(String token) =>
      _pets.getUserArchivedPets(token);

  Future<List<Map<String, dynamic>>> getFamilyEvents(
    String token,
    String petId,
  ) => _pets.getFamilyEvents(token, petId);

  Future<Map<String, dynamic>> createFamilyEvent(
    String token,
    String petId,
    Map<String, dynamic> body,
  ) => _pets.createFamilyEvent(token, petId, body);

  Future<void> updateFamilyEvent(
    String token,
    String petId,
    String eventId,
    Map<String, dynamic> body,
  ) => _pets.updateFamilyEvent(token, petId, eventId, body);

  Future<void> deleteFamilyEvent(String token, String petId, String eventId) =>
      _pets.deleteFamilyEvent(token, petId, eventId);

  Future<List<Map<String, dynamic>>> getFosterParents(
    String orgId,
    String token,
  ) => _fosterParents.getFosterParents(orgId, token);

  Future<List<Map<String, dynamic>>> getPeople(String orgId, String token) =>
      _fosterParents.getPeople(orgId, token);

  Future<Map<String, dynamic>> getPersonDetail(
    String orgId,
    String kind,
    String recordId,
    String token,
  ) => _fosterParents.getPersonDetail(orgId, kind, recordId, token);

  Future<Map<String, dynamic>> updatePersonContact(
    String orgId,
    String kind,
    String recordId,
    Map<String, dynamic> body,
    String token,
  ) => _fosterParents.updatePersonContact(orgId, kind, recordId, body, token);

  Future<Map<String, dynamic>> createExternalFosterParent(
    String orgId, {
    required String displayName,
    required String email,
    String? phone,
    String fosterAddress = '',
    String notes = '',
    required bool lawfulBasisConfirmed,
    required String token,
  }) => _fosterParents.createExternalFosterParent(
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
  }) => _fosterParents.updateExternalFosterParent(
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
  ) => _fosterParents.deleteExternalFosterParent(orgId, fosterParentId, token);

  Future<Map<String, dynamic>> updateFosterApproval(
    String orgId,
    String fosterParentId,
    String approvalState,
    String token,
  ) => _fosterParents.updateFosterApproval(
    orgId,
    fosterParentId,
    approvalState,
    token,
  );

  Future<List<Map<String, dynamic>>> getFosterMergeSuggestions(
    String orgId,
    String email,
    String token,
  ) => _fosterParents.getFosterMergeSuggestions(orgId, email, token);

  Future<Map<String, dynamic>> mergeManualFoster(
    String orgId,
    String fosterParentId, {
    required String targetUserId,
    required String token,
  }) => _fosterParents.mergeManualFoster(
    orgId,
    fosterParentId,
    targetUserId: targetUserId,
    token: token,
  );

  Future<Map<String, dynamic>> getPetPlacement(
    String orgId,
    String petId,
    String token,
  ) => _placements.getPetPlacement(orgId, petId, token);

  Future<Map<String, dynamic>> startFosterPlacement(
    String orgId,
    String petId, {
    required String fosterUserId,
    String? startDate,
    String notes = '',
    required String token,
  }) => _placements.startFosterPlacement(
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
  }) => _placements.endFosterPlacement(
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
  }) => _placements.startAdoption(
    orgId,
    placementId,
    adoptionConditions: adoptionConditions,
    token: token,
  );

  Future<Map<String, dynamic>> completeAdoptionConditions(
    String orgId,
    String placementId, {
    required String token,
  }) =>
      _placements.completeAdoptionConditions(orgId, placementId, token: token);

  Future<Map<String, dynamic>> cancelAdoption(
    String orgId,
    String placementId, {
    String? endDate,
    required String token,
  }) => _placements.cancelAdoption(
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
  }) => _placements.directAdopt(
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
  ) => _placements.getPetFosterHistory(orgId, petId, token);

  Future<List<OrgConnection>> getConnections(String orgId, String token) =>
      _connections.getConnections(orgId, token);

  Future<Map<String, dynamic>> createConnectionRequest(
    String orgId, {
    required String targetOrgId,
    required String token,
  }) => _connections.createConnectionRequest(
    orgId,
    targetOrgId: targetOrgId,
    token: token,
  );

  Future<List<OrgConnectionRequest>> getConnectionRequests(
    String orgId,
    String token,
  ) => _connections.getConnectionRequests(orgId, token);

  Future<void> revokeConnectionRequest(
    String orgId,
    String requestId,
    String token,
  ) => _connections.revokeConnectionRequest(orgId, requestId, token);

  Future<void> acceptConnectionRequest(String token, String requestToken) =>
      _connections.acceptConnectionRequest(token, requestToken);

  Future<void> disconnectOrgs(String orgId, String otherOrgId, String token) =>
      _connections.disconnectOrgs(orgId, otherOrgId, token);

  Future<Map<String, dynamic>> requestCustodyTransfer(
    String orgId,
    String petId, {
    required String transferKind,
    String? toOrgId,
    String? toUserId,
    String notes = '',
    required String token,
  }) => _custody.requestCustodyTransfer(
    orgId,
    petId,
    transferKind: transferKind,
    toOrgId: toOrgId,
    toUserId: toUserId,
    notes: notes,
    token: token,
  );

  Future<List<CustodyTransfer>> getPendingCustodyTransfers(String token) =>
      _custody.getPendingCustodyTransfers(token);

  Future<void> acceptCustodyTransfer(String transferId, String token) =>
      _custody.acceptCustodyTransfer(transferId, token);

  Future<void> cancelCustodyTransfer(
    String transferId,
    String token, {
    String reason = '',
  }) => _custody.cancelCustodyTransfer(transferId, token, reason: reason);

  Future<void> setPetHomeHidden(
    String orgId,
    String petId, {
    required bool hidden,
    required String token,
  }) => _custody.setPetHomeHidden(orgId, petId, hidden: hidden, token: token);

  Future<List<Map<String, dynamic>>> getHomeHiddenPets(
    String orgId,
    String token,
  ) => _custody.getHomeHiddenPets(orgId, token);
}
