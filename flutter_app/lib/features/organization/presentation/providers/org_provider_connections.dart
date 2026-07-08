import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/org_connection.dart';
import 'org_provider_custody.dart';
import 'org_provider_deps.dart';
import 'org_provider_list.dart';

class OrgConnectionsNotifier extends FamilyAsyncNotifier<List<OrgConnection>, String> {
  @override
  Future<List<OrgConnection>> build(String orgId) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) return [];
    final repo = ref.read(organizationRepositoryProvider);
    return repo.getConnections(orgId, token);
  }

  Future<String> createRequest(String targetOrgId) async {
    final token = ref.read(orgTokenProvider);
    if (token == null) throw StateError('Not authenticated');
    final repo = ref.read(organizationRepositoryProvider);
    final result = await repo.createConnectionRequest(
      arg,
      targetOrgId: targetOrgId,
      token: token,
    );
    ref.invalidate(orgConnectionRequestsProvider(arg));
    return result['token']?.toString() ?? '';
  }

  Future<void> disconnect(String otherOrgId) async {
    final token = ref.read(orgTokenProvider);
    if (token == null) return;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.disconnectOrgs(arg, otherOrgId, token);
    ref.invalidateSelf();
    ref.invalidate(pendingCustodyTransfersProvider);
  }
}

final orgConnectionsProvider =
    AsyncNotifierProvider.family<OrgConnectionsNotifier, List<OrgConnection>, String>(
      OrgConnectionsNotifier.new,
    );

class OrgConnectionRequestsNotifier
    extends FamilyAsyncNotifier<List<OrgConnectionRequest>, String> {
  @override
  Future<List<OrgConnectionRequest>> build(String orgId) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) return [];
    final repo = ref.read(organizationRepositoryProvider);
    return repo.getConnectionRequests(orgId, token);
  }

  Future<void> revoke(String requestId) async {
    final token = ref.read(orgTokenProvider);
    if (token == null) return;
    final repo = ref.read(organizationRepositoryProvider);
    await repo.revokeConnectionRequest(arg, requestId, token);
    ref.invalidateSelf();
  }
}

final orgConnectionRequestsProvider =
    AsyncNotifierProvider.family<
      OrgConnectionRequestsNotifier,
      List<OrgConnectionRequest>,
      String
    >(OrgConnectionRequestsNotifier.new);

Future<void> acceptOrgConnectionToken(WidgetRef ref, String token) async {
  final authToken = ref.read(orgTokenProvider);
  if (authToken == null) return;
  final repo = ref.read(organizationRepositoryProvider);
  await repo.acceptConnectionRequest(authToken, token);
  ref.invalidate(organizationListProvider);
}
