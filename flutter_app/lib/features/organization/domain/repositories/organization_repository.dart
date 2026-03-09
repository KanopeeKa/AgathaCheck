import 'dart:typed_data';

import '../entities/archived_pet.dart';
import '../entities/organization.dart';
import '../entities/organization_member.dart';

abstract class OrganizationRepository {
  Future<List<Organization>> getOrganizations(String token);
  Future<Organization> getOrganization(int id, String token);
  Future<Organization> createOrganization(Organization org, String token);
  Future<Organization> updateOrganization(Organization org, String token);
  Future<void> deleteOrganization(int id, String token);
  Future<Organization> uploadPhoto(int id, Uint8List bytes, String filename, String token);

  Future<List<OrganizationMember>> getMembers(int orgId, String token);
  Future<String> inviteMember(int orgId, String token);
  Future<void> joinOrganization(String code, String token);
  Future<void> updateMemberRole(int orgId, int userId, OrgMemberRole role, String token);
  Future<void> removeMember(int orgId, int userId, String token);
  Future<void> leaveOrganization(int orgId, String token);

  Future<List<Map<String, dynamic>>> getOrganizationPets(int orgId, String token);
  Future<Map<String, dynamic>> createOrganizationPet(int orgId, Map<String, dynamic> petJson, String token);
  Future<void> transferPetToUser(int orgId, String petId, {required String recipientEmail, String notes, required String token});
  Future<void> transferPetToOrg(String petId, int orgId, {String notes, required String token});

  Future<List<ArchivedPet>> getOrganizationArchivedPets(int orgId, String token);
  Future<List<ArchivedPet>> getUserArchivedPets(String token);
}
