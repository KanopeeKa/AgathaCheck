import 'package:pet_profile_app/features/organization/domain/entities/custody_transfer.dart';
import 'package:pet_profile_app/features/organization/domain/entities/org_connection.dart';
import 'package:pet_profile_app/features/organization/domain/entities/org_home_hidden_pet.dart';

import 'recording_organization_repository_base.dart';

mixin RecordingOrganizationRepositoryConnectionsMixin
    on RecordingOrganizationRepositoryBase {
  @override
  Future<List<OrgConnection>> getConnections(
    String orgId,
    String token,
  ) async => [];

  @override
  Future<Map<String, dynamic>> createConnectionRequest(
    String orgId, {
    required String targetOrgId,
    required String token,
  }) async => {'token': 'test-token'};

  @override
  Future<List<OrgConnectionRequest>> getConnectionRequests(
    String orgId,
    String token,
  ) async => [];

  @override
  Future<void> revokeConnectionRequest(
    String orgId,
    String requestId,
    String token,
  ) async {}

  @override
  Future<void> acceptConnectionRequest(
    String token,
    String requestToken,
  ) async {}

  @override
  Future<void> disconnectOrgs(
    String orgId,
    String otherOrgId,
    String token,
  ) async {}

  @override
  Future<Map<String, dynamic>> requestCustodyTransfer(
    String orgId,
    String petId, {
    required String transferKind,
    String? toOrgId,
    String? toUserId,
    String notes = '',
    required String token,
  }) async => {'id': 'transfer-1', 'status': 'pending'};

  @override
  Future<List<CustodyTransfer>> getPendingCustodyTransfers(
    String token,
  ) async => [];

  @override
  Future<void> acceptCustodyTransfer(String transferId, String token) async {}

  @override
  Future<void> cancelCustodyTransfer(
    String transferId,
    String token, {
    String reason = '',
  }) async {}

  @override
  Future<void> setPetHomeHidden(
    String orgId,
    String petId, {
    required bool hidden,
    required String token,
  }) async {}

  @override
  Future<List<OrgHomeHiddenPet>> getHomeHiddenPets(
    String orgId,
    String token,
  ) async => [];
}
