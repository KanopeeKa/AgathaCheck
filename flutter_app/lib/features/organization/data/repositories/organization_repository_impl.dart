import 'dart:typed_data';

import '../../domain/entities/archived_pet.dart';
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
  Future<Organization> getOrganization(int id, String token) async {
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
  Future<void> deleteOrganization(int id, String token) async {
    await _dataSource.deleteOrganization(id, token);
  }

  @override
  Future<Organization> uploadPhoto(
      int id, Uint8List bytes, String filename, String token) async {
    return await _dataSource.uploadPhoto(id, bytes, filename, token);
  }

  @override
  Future<List<OrganizationMember>> getMembers(int orgId, String token) async {
    return await _dataSource.getMembers(orgId, token);
  }

  @override
  Future<String> inviteMember(int orgId, String token) async {
    return await _dataSource.inviteMember(orgId, token);
  }

  @override
  Future<void> joinOrganization(String code, String token) async {
    await _dataSource.joinOrganization(code, token);
  }

  @override
  Future<void> updateMemberRole(
      int orgId, int userId, OrgMemberRole role, String token) async {
    final roleStr = role == OrgMemberRole.superUser ? 'super_user' : 'member';
    await _dataSource.updateMemberRole(orgId, userId, roleStr, token);
  }

  @override
  Future<void> removeMember(int orgId, int userId, String token) async {
    await _dataSource.removeMember(orgId, userId, token);
  }

  @override
  Future<void> leaveOrganization(int orgId, String token) async {
    await _dataSource.leaveOrganization(orgId, token);
  }

  @override
  Future<List<Map<String, dynamic>>> getOrganizationPets(
      int orgId, String token) async {
    return await _dataSource.getOrganizationPets(orgId, token);
  }

  @override
  Future<Map<String, dynamic>> createOrganizationPet(
      int orgId, Map<String, dynamic> petJson, String token) async {
    return await _dataSource.createOrganizationPet(orgId, petJson, token);
  }

  @override
  Future<void> transferPetToUser(
      int orgId, String petId, {required String recipientEmail, String notes = '', required String token}) async {
    await _dataSource.transferPetToUser(
      orgId,
      petId,
      recipientEmail: recipientEmail,
      notes: notes,
      token: token,
    );
  }

  @override
  Future<void> transferPetToOrg(
      String petId, int orgId, {String notes = '', required String token}) async {
    await _dataSource.transferPetToOrg(
      petId,
      orgId,
      notes: notes,
      token: token,
    );
  }

  @override
  Future<List<ArchivedPet>> getOrganizationArchivedPets(
      int orgId, String token) async {
    return await _dataSource.getOrganizationArchivedPets(orgId, token);
  }

  @override
  Future<List<ArchivedPet>> getUserArchivedPets(String token) async {
    return await _dataSource.getUserArchivedPets(token);
  }
}
