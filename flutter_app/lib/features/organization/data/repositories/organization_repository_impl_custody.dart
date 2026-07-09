import '../../domain/entities/custody_transfer.dart';
import '../../domain/entities/org_connection.dart';
import '../../domain/entities/org_home_hidden_pet.dart';
import 'organization_repository_impl_base.dart';

mixin OrganizationRepositoryCustodyMixin on OrganizationRepositoryImplBase {
  @override
  Future<List<OrgConnection>> getConnections(String orgId, String token) =>
      dataSource.getConnections(orgId, token);

  @override
  Future<Map<String, dynamic>> createConnectionRequest(
    String orgId, {
    required String targetOrgId,
    required String token,
  }) => dataSource.createConnectionRequest(
    orgId,
    targetOrgId: targetOrgId,
    token: token,
  );

  @override
  Future<List<OrgConnectionRequest>> getConnectionRequests(
    String orgId,
    String token,
  ) => dataSource.getConnectionRequests(orgId, token);

  @override
  Future<void> revokeConnectionRequest(
    String orgId,
    String requestId,
    String token,
  ) => dataSource.revokeConnectionRequest(orgId, requestId, token);

  @override
  Future<void> acceptConnectionRequest(String token, String requestToken) =>
      dataSource.acceptConnectionRequest(token, requestToken);

  @override
  Future<void> disconnectOrgs(String orgId, String otherOrgId, String token) =>
      dataSource.disconnectOrgs(orgId, otherOrgId, token);

  @override
  Future<Map<String, dynamic>> requestCustodyTransfer(
    String orgId,
    String petId, {
    required String transferKind,
    String? toOrgId,
    String? toUserId,
    String notes = '',
    required String token,
  }) => dataSource.requestCustodyTransfer(
    orgId,
    petId,
    transferKind: transferKind,
    toOrgId: toOrgId,
    toUserId: toUserId,
    notes: notes,
    token: token,
  );

  @override
  Future<List<CustodyTransfer>> getPendingCustodyTransfers(String token) =>
      dataSource.getPendingCustodyTransfers(token);

  @override
  Future<void> acceptCustodyTransfer(String transferId, String token) =>
      dataSource.acceptCustodyTransfer(transferId, token);

  @override
  Future<void> cancelCustodyTransfer(
    String transferId,
    String token, {
    String reason = '',
  }) => dataSource.cancelCustodyTransfer(transferId, token, reason: reason);

  @override
  Future<void> setPetHomeHidden(
    String orgId,
    String petId, {
    required bool hidden,
    required String token,
  }) => dataSource.setPetHomeHidden(orgId, petId, hidden: hidden, token: token);

  @override
  Future<List<OrgHomeHiddenPet>> getHomeHiddenPets(
    String orgId,
    String token,
  ) async {
    final rows = await dataSource.getHomeHiddenPets(orgId, token);
    return rows
        .map(
          (row) => OrgHomeHiddenPet(
            petId: row['pet_id']?.toString() ?? '',
            petName: row['pet_name']?.toString() ?? '',
            hiddenAt: row['created_at'] != null
                ? DateTime.tryParse(row['created_at'].toString())
                : null,
          ),
        )
        .toList();
  }
}
