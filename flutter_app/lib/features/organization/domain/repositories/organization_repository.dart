import 'dart:typed_data';

import '../entities/archived_pet.dart';
import '../entities/organization.dart';
import '../entities/organization_member.dart';

abstract class OrganizationRepository {
  Future<List<Organization>> getOrganizations(String token);
  Future<Organization> getOrganization(String id, String token);
  Future<Organization> createOrganization(Organization org, String token);
  Future<Organization> updateOrganization(Organization org, String token);
  Future<void> deleteOrganization(String id, String token);
  Future<Organization> uploadPhoto(String id, Uint8List bytes, String filename, String token);

  Future<List<OrganizationMember>> getMembers(String orgId, String token);
  Future<String> inviteMember(String orgId, String token);
  Future<void> joinOrganization(String code, String token);
  Future<void> updateMemberRole(String orgId, String userId, OrgMemberRole role, String token);
  Future<void> removeMember(String orgId, String userId, String token);
  Future<void> leaveOrganization(String orgId, String token);

  Future<List<Map<String, dynamic>>> getOrganizationPets(String orgId, String token);
  Future<Map<String, dynamic>> createOrganizationPet(String orgId, Map<String, dynamic> petJson, String token);
  Future<void> transferPetToUser(String orgId, String petId, {required String recipientEmail, String notes, required String token});
  Future<void> transferPetToOrg(String petId, String orgId, {String notes, required String token});

  Future<List<ArchivedPet>> getOrganizationArchivedPets(String orgId, String token);
  Future<List<ArchivedPet>> getUserArchivedPets(String token);
}
