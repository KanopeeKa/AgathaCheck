import 'dart:typed_data';

import '../entities/archived_pet.dart';
import '../entities/foster_parent.dart';
import '../entities/foster_placement.dart';
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
}
