import 'dart:typed_data';

import '../../domain/entities/organization.dart';
import '../../domain/entities/organization_member.dart';
import '../../domain/repositories/organization_repository.dart';
import '../datasources/organization_remote_datasource.dart';
import '../models/organization_model.dart';

/// Shared datasource handle for modular repository mixins.
abstract class OrganizationRepositoryImplBase
    implements OrganizationRepository {
  OrganizationRepositoryImplBase(this.dataSource);

  final OrganizationRemoteDataSource dataSource;

  @override
  Future<List<Organization>> getOrganizations(String token) async {
    return await dataSource.getOrganizations(token);
  }

  @override
  Future<Organization> getOrganization(String id, String token) async {
    return await dataSource.getOrganization(id, token);
  }

  @override
  Future<Organization> getPublicOrganization(
    String id, {
    String? token,
  }) async {
    return await dataSource.getPublicOrganization(id, token: token);
  }

  @override
  Future<Organization> createOrganization(
    Organization org,
    String token,
  ) async {
    final model = OrganizationModel.fromEntity(org);
    return await dataSource.createOrganization(model.toJson(), token);
  }

  @override
  Future<Organization> updateOrganization(
    Organization org,
    String token,
  ) async {
    final model = OrganizationModel.fromEntity(org);
    return await dataSource.updateOrganization(org.id, model.toJson(), token);
  }

  @override
  Future<void> deleteOrganization(String id, String token) async {
    await dataSource.deleteOrganization(id, token);
  }

  @override
  Future<Organization> uploadPhoto(
    String id,
    Uint8List bytes,
    String filename,
    String token,
  ) async {
    return await dataSource.uploadPhoto(id, bytes, filename, token);
  }

  @override
  Future<Organization> uploadLogo(
    String id,
    Uint8List bytes,
    String filename,
    String token,
  ) async {
    return await dataSource.uploadLogo(id, bytes, filename, token);
  }

  @override
  Future<Organization> setPrimaryContact(
    String orgId,
    String recordId,
    String token,
  ) async {
    return await dataSource.setPrimaryContact(orgId, recordId, token);
  }

  @override
  Future<List<OrganizationMember>> getMembers(
    String orgId,
    String token,
  ) async {
    return await dataSource.getMembers(orgId, token);
  }

  @override
  Future<Map<String, dynamic>> inviteByEmail(
    String orgId,
    String email,
    String role,
    String token,
  ) async {
    return await dataSource.inviteByEmail(orgId, email, role, token);
  }

  @override
  Future<List<Map<String, dynamic>>> getPendingInvites(String token) async {
    return await dataSource.getPendingInvites(token);
  }

  @override
  Future<Map<String, dynamic>> acceptInvite(
    String inviteId,
    String token,
  ) async {
    return await dataSource.acceptInvite(inviteId, token);
  }

  @override
  Future<void> declineInvite(String inviteId, String token) async {
    await dataSource.declineInvite(inviteId, token);
  }

  @override
  Future<void> updateMemberRole(
    String orgId,
    String userId,
    OrgMemberRole role,
    String token,
  ) async {
    await dataSource.updateMemberRole(orgId, userId, role.toWire(), token);
  }

  @override
  Future<void> removeMember(String orgId, String userId, String token) async {
    await dataSource.removeMember(orgId, userId, token);
  }

  @override
  Future<void> leaveOrganization(String orgId, String token) async {
    await dataSource.leaveOrganization(orgId, token);
  }
}
