import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/archived_pet_model.dart';
import '../models/organization_member_model.dart';
import '../models/organization_model.dart';
import '../../domain/entities/custody_transfer.dart';
import '../../domain/entities/org_connection.dart';
import 'organization_remote/organization_adoption_screening_remote.dart';
import 'organization_remote/organization_connections_remote.dart';
import 'organization_remote/organization_custody_remote.dart';
import 'organization_remote/organization_core_remote.dart';
import 'organization_remote/organization_foster_parents_remote.dart';
import 'organization_remote/organization_foster_requests_remote.dart';
import 'organization_remote/organization_invites_remote.dart';
import 'organization_remote/organization_members_remote.dart';
import 'organization_remote/organization_permissions_remote.dart';
import 'organization_remote/organization_pets_remote.dart';
import 'organization_remote/organization_placements_remote.dart';
import 'organization_remote/organization_remote_context.dart';
import 'organization_remote_foster_delegations.dart';

/// Facade over modular organization HTTP clients. Mirrors `server/routes/organizations/`.
class OrganizationRemoteDataSource with OrganizationRemoteFosterDelegations {
  OrganizationRemoteDataSource({String? baseUrl, http.Client? client})
    : _ctx = OrganizationRemoteContext(baseUrl: baseUrl, client: client) {
    _core = OrganizationCoreRemote(_ctx);
    _invites = OrganizationInvitesRemote(_ctx);
    _members = OrganizationMembersRemote(_ctx);
    _pets = OrganizationPetsRemote(_ctx);
    fosterParentsRemote = OrganizationFosterParentsRemote(_ctx);
    fosterRequestsRemote = OrganizationFosterRequestsRemote(_ctx);
    placementsRemote = OrganizationPlacementsRemote(_ctx);
    _screening = OrganizationAdoptionScreeningRemote(_ctx);
    _connections = OrganizationConnectionsRemote(_ctx);
    _custody = OrganizationCustodyRemote(_ctx);
    _permissions = OrganizationPermissionsRemote(_ctx);
  }

  final OrganizationRemoteContext _ctx;
  late final OrganizationCoreRemote _core;
  late final OrganizationInvitesRemote _invites;
  late final OrganizationMembersRemote _members;
  late final OrganizationPetsRemote _pets;
  @override
  late final OrganizationFosterParentsRemote fosterParentsRemote;
  @override
  late final OrganizationFosterRequestsRemote fosterRequestsRemote;
  @override
  late final OrganizationPlacementsRemote placementsRemote;
  late final OrganizationAdoptionScreeningRemote _screening;
  late final OrganizationConnectionsRemote _connections;
  late final OrganizationCustodyRemote _custody;
  late final OrganizationPermissionsRemote _permissions;

  String get baseUrl => _ctx.baseUrl;

  Future<List<OrganizationModel>> getOrganizations(String token) =>
      _core.getOrganizations(token);

  Future<OrganizationModel> getOrganization(String id, String token) =>
      _core.getOrganization(id, token);

  Future<OrganizationModel> getPublicOrganization(String id, {String? token}) =>
      _core.getPublicOrganization(id, token: token);

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

  Future<Map<String, dynamic>> getMemberPrivacy(String orgId, String token) =>
      _members.getMemberPrivacy(orgId, token);

  Future<Map<String, dynamic>> updateMemberPrivacy(
    String orgId,
    Map<String, dynamic> body,
    String token,
  ) => _members.updateMemberPrivacy(orgId, body, token);

  Future<List<Map<String, dynamic>>> getOrganizationPets(
    String orgId,
    String token,
  ) => _pets.getOrganizationPets(orgId, token);

  Future<List<Map<String, dynamic>>> getOrganizationPetSummary(
    String orgId,
    String token,
  ) => _pets.getOrganizationPetSummary(orgId, token);

  Future<Map<String, dynamic>> getRedactedOrganizationPet(
    String orgId,
    String petId,
    String token,
  ) => _pets.getRedactedOrganizationPet(orgId, petId, token);

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

  Future<List<Map<String, dynamic>>> getProspects(String orgId, String token) =>
      _screening.getProspects(orgId, token);

  Future<List<Map<String, dynamic>>> getAdoptionVisits(
    String orgId,
    String token,
  ) => _screening.getAdoptionVisits(orgId, token);

  Future<Map<String, dynamic>> getAdoptionJourney(
    String orgId,
    String placementId,
    String token,
  ) => _screening.getAdoptionJourney(orgId, placementId, token);

  Future<Map<String, dynamic>> getSessionChecklist(
    String orgId,
    String placementId,
    String token,
  ) => _screening.getSessionChecklist(orgId, placementId, token);

  Future<Map<String, dynamic>> updateSessionChecklistItem(
    String orgId,
    String placementId,
    String itemKey, {
    required bool completed,
    required String token,
  }) => _screening.updateSessionChecklistItem(
    orgId,
    placementId,
    itemKey,
    completed: completed,
    token: token,
  );

  Future<Map<String, dynamic>> getAdoptionMilestones(
    String orgId,
    String placementId,
    String token,
  ) => _screening.getAdoptionMilestones(orgId, placementId, token);

  Future<Map<String, dynamic>> updateAdoptionMilestoneItem(
    String orgId,
    String journeyId,
    String itemKey, {
    required bool completed,
    required String token,
  }) => _screening.updateAdoptionMilestoneItem(
    orgId,
    journeyId,
    itemKey,
    completed: completed,
    token: token,
  );

  Future<Map<String, dynamic>> getRegisterExport(
    String orgId,
    String placementId,
    String token,
  ) => _screening.getRegisterExport(orgId, placementId, token);

  Future<Map<String, dynamic>> recordAdoptionVisitOutcome(
    String orgId,
    String visitId,
    String visitOutcome,
    String token,
  ) => _screening.recordAdoptionVisitOutcome(
    orgId,
    visitId,
    visitOutcome,
    token,
  );

  Future<Map<String, dynamic>> completeVisitAndStartAdoption(
    String orgId,
    String placementId, {
    String? visitId,
    String adoptionConditions = '',
    required String token,
  }) => _screening.completeVisitAndStartAdoption(
    orgId,
    placementId,
    visitId: visitId,
    adoptionConditions: adoptionConditions,
    token: token,
  );

  Future<Map<String, dynamic>> getPermissionBundles(
    String orgId,
    String token,
  ) => _permissions.getPermissionBundles(orgId, token);

  Future<Map<String, dynamic>> getMyPermissions(String orgId, String token) =>
      _permissions.getMyPermissions(orgId, token);

  Future<Map<String, dynamic>> getMemberPermissions(
    String orgId,
    String targetUserId,
    String token,
  ) => _permissions.getMemberPermissions(orgId, targetUserId, token);

  Future<Map<String, dynamic>> applyPermissionBundle(
    String orgId,
    String targetUserId,
    String preset,
    String token,
  ) => _permissions.applyPermissionBundle(orgId, targetUserId, preset, token);

  Future<Map<String, dynamic>> grantPermission(
    String orgId,
    String targetUserId,
    String permissionKey,
    String token,
  ) => _permissions.grantPermission(orgId, targetUserId, permissionKey, token);

  Future<Map<String, dynamic>> revokePermission(
    String orgId,
    String targetUserId,
    String permissionKey,
    String token,
  ) => _permissions.revokePermission(orgId, targetUserId, permissionKey, token);

  Future<Map<String, dynamic>> batchPermissions(
    String orgId,
    List<Map<String, dynamic>> changes,
    String token,
  ) => _permissions.batchPermissions(orgId, changes, token);

  Future<List<Map<String, dynamic>>> getAuditEvents(
    String orgId,
    String token,
  ) => _permissions.getAuditEvents(orgId, token);

  Future<Map<String, dynamic>> getDocumentTemplates(
    String orgId,
    String token,
  ) => _permissions.getDocumentTemplates(orgId, token);

  Future<Map<String, dynamic>> updateEmailTemplate(
    String orgId,
    String templateKey, {
    required String subject,
    required String bodyHtml,
    required String bodyText,
    required String token,
  }) => _permissions.updateEmailTemplate(
    orgId,
    templateKey,
    subject: subject,
    bodyHtml: bodyHtml,
    bodyText: bodyText,
    token: token,
  );

  Future<Map<String, dynamic>> getRolePermissionDefaults(
    String orgId,
    String token,
  ) => _permissions.getRolePermissionDefaults(orgId, token);

  Future<Map<String, dynamic>> saveRolePermissionDefaults(
    String orgId,
    String tier,
    List<String> grantedKeys,
    String token,
  ) => _permissions.saveRolePermissionDefaults(orgId, tier, grantedKeys, token);
}
