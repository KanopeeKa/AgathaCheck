import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/foster_placement.dart';
import 'foster_placements_providers.dart';
import 'org_provider_deps.dart';

typedef FosteringSessionDetailKey = ({String orgId, String placementId});

class FosteringSessionDetailNotifier
    extends FamilyAsyncNotifier<FosterPlacement, FosteringSessionDetailKey> {
  @override
  Future<FosterPlacement> build(FosteringSessionDetailKey key) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) {
      throw StateError('Not authenticated');
    }
    final repo = ref.read(organizationRepositoryProvider);
    return repo.getPlacementDetail(key.orgId, key.placementId, token);
  }

  Future<FosterPlacement> transitionSession(String sessionStatus) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    final updated = await repo.transitionFosteringSession(
      arg.orgId,
      arg.placementId,
      sessionStatus: sessionStatus,
      token: token,
    );
    ref.invalidateSelf();
    ref.invalidate(petFosterPlacementProvider((arg.orgId, updated.petId)));
    return updated;
  }

  Future<FosterPlacement> confirmShelterStart() async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    final updated = await repo.confirmShelterSessionStart(
      arg.orgId,
      arg.placementId,
      token: token,
    );
    ref.invalidateSelf();
    ref.invalidate(petFosterPlacementProvider((arg.orgId, updated.petId)));
    return updated;
  }

  Future<FosterPlacement> confirmFosterStart() async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    final updated = await repo.confirmFosterSessionStart(
      arg.orgId,
      arg.placementId,
      token: token,
    );
    ref.invalidateSelf();
    ref.invalidate(petFosterPlacementProvider((arg.orgId, updated.petId)));
    return updated;
  }

  Future<FosterPlacement> requestEnd() async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    final updated = await repo.requestFosteringSessionEnd(
      arg.orgId,
      arg.placementId,
      token: token,
    );
    ref.invalidateSelf();
    ref.invalidate(petFosterPlacementProvider((arg.orgId, updated.petId)));
    return updated;
  }

  Future<FosterPlacement> endSession({
    required String outcome,
    DateTime? endDate,
  }) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    final updated = await repo.endFosteringSession(
      arg.orgId,
      arg.placementId,
      outcome: outcome,
      endDate: endDate,
      token: token,
    );
    ref.invalidateSelf();
    ref.invalidate(petFosterPlacementProvider((arg.orgId, updated.petId)));
    return updated;
  }
}

final fosteringSessionDetailProvider =
    AsyncNotifierProvider.family<
      FosteringSessionDetailNotifier,
      FosterPlacement,
      FosteringSessionDetailKey
    >(FosteringSessionDetailNotifier.new);
