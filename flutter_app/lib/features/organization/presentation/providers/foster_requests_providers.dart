import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/foster_parent.dart';
import '../../domain/entities/foster_request.dart';
import 'org_provider_deps.dart';

class OrgFosterRequestsNotifier
    extends FamilyAsyncNotifier<List<FosterRequest>, String> {
  @override
  Future<List<FosterRequest>> build(String orgId) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) return [];
    final repo = ref.read(organizationRepositoryProvider);
    return repo.getFosterRequests(orgId, token);
  }

  Future<FosterRequest> createRequest({
    required String message,
    required List<String> petIds,
    required List<String> orgFosterParentIds,
    bool send = false,
  }) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    final request = await repo.createFosterRequest(
      arg,
      message: message,
      petIds: petIds,
      orgFosterParentIds: orgFosterParentIds,
      send: send,
      token: token,
    );
    ref.invalidateSelf();
    return request;
  }

  Future<FosterRequest> sendRequest(String requestId) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    final request = await repo.sendFosterRequest(arg, requestId, token: token);
    ref.invalidateSelf();
    ref.invalidate(
      orgFosterRequestDetailProvider((orgId: arg, requestId: requestId)),
    );
    return request;
  }
}

final orgFosterRequestsProvider =
    AsyncNotifierProvider.family<
      OrgFosterRequestsNotifier,
      List<FosterRequest>,
      String
    >(OrgFosterRequestsNotifier.new);

typedef OrgFosterRequestDetailKey = ({String orgId, String requestId});

class OrgFosterRequestDetailNotifier
    extends FamilyAsyncNotifier<FosterRequest, OrgFosterRequestDetailKey> {
  @override
  Future<FosterRequest> build(OrgFosterRequestDetailKey key) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) {
      throw StateError('Not authenticated');
    }
    final repo = ref.read(organizationRepositoryProvider);
    return repo.getFosterRequestDetail(key.orgId, key.requestId, token);
  }

  Future<FosterRequest> respond({
    required FosterResponseType response,
    String? message,
    DateTime? earliestAvailability,
  }) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    final updated = await repo.respondToFosterRequest(
      arg.orgId,
      arg.requestId,
      response: response,
      message: message,
      earliestAvailability: earliestAvailability,
      token: token,
    );
    ref.invalidateSelf();
    ref.invalidate(orgFosterRequestsProvider(arg.orgId));
    return updated;
  }

  Future<FosterRequest> sendDraft() async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    final updated = await repo.sendFosterRequest(
      arg.orgId,
      arg.requestId,
      token: token,
    );
    ref.invalidateSelf();
    ref.invalidate(orgFosterRequestsProvider(arg.orgId));
    return updated;
  }
}

final orgFosterRequestDetailProvider =
    AsyncNotifierProvider.family<
      OrgFosterRequestDetailNotifier,
      FosterRequest,
      OrgFosterRequestDetailKey
    >(OrgFosterRequestDetailNotifier.new);

List<FosterParent> eligibleFosterRequestTargets(List<FosterParent> parents) {
  return parents
      .where(
        (p) =>
            p.approvalState == FosterApprovalState.approved &&
            !p.hasOutreachOptOut,
      )
      .toList(growable: false);
}
