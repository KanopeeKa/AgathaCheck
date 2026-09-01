import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../fostering_session/domain/entities/fostering_session_detail.dart';
import '../../../fostering_session/presentation/providers/fostering_session_repository_provider.dart';
import '../../domain/entities/foster_placement.dart';
import 'foster_placements_providers.dart';
import 'org_provider_deps.dart';

typedef FosteringSessionDetailKey = ({String placementId, String? orgId});

class FosteringSessionDetailNotifier
    extends
        FamilyAsyncNotifier<FosteringSessionDetail, FosteringSessionDetailKey> {
  @override
  Future<FosteringSessionDetail> build(FosteringSessionDetailKey key) async {
    final token = ref.watch(orgTokenProvider);
    if (token == null) {
      throw StateError('Not authenticated');
    }
    final orgId = key.orgId;
    if (orgId == null || orgId.isEmpty) {
      final repo = ref.read(fosterFosteringSessionRepositoryProvider);
      return repo.getFosterSessionDetail(key.placementId, token);
    }
    final repo = ref.read(shelterFosteringSessionRepositoryProvider);
    return repo.getSessionDetail(orgId, key.placementId, token);
  }

  String get _orgId {
    final fromKey = arg.orgId;
    if (fromKey != null && fromKey.isNotEmpty) return fromKey;
    final current = state.valueOrNull;
    if (current != null && current.placement.organizationId.isNotEmpty) {
      return current.placement.organizationId;
    }
    throw StateError('Organization id unavailable for session mutation');
  }

  Future<FosterPlacement> transitionSession(String sessionStatus) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    final updated = await repo.transitionFosteringSession(
      _orgId,
      arg.placementId,
      sessionStatus: sessionStatus,
      token: token,
    );
    ref.invalidateSelf();
    ref.invalidate(petFosterPlacementProvider((_orgId, updated.petId)));
    return updated;
  }

  Future<FosterPlacement> confirmShelterStart() async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    final updated = await repo.confirmShelterSessionStart(
      _orgId,
      arg.placementId,
      token: token,
    );
    ref.invalidateSelf();
    ref.invalidate(petFosterPlacementProvider((_orgId, updated.petId)));
    return updated;
  }

  Future<FosterPlacement> confirmFosterStart() async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    final updated = await repo.confirmFosterSessionStart(
      _orgId,
      arg.placementId,
      token: token,
    );
    ref.invalidateSelf();
    ref.invalidate(petFosterPlacementProvider((_orgId, updated.petId)));
    return updated;
  }

  Future<FosterPlacement> requestEnd() async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    final updated = await repo.requestFosteringSessionEnd(
      _orgId,
      arg.placementId,
      token: token,
    );
    ref.invalidateSelf();
    ref.invalidate(petFosterPlacementProvider((_orgId, updated.petId)));
    return updated;
  }

  Future<FosterPlacement> endSession({
    required String outcome,
    DateTime? endDate,
  }) async {
    final token = ref.read(orgTokenProvider)!;
    final repo = ref.read(organizationRepositoryProvider);
    final updated = await repo.endFosteringSession(
      _orgId,
      arg.placementId,
      outcome: outcome,
      endDate: endDate,
      token: token,
    );
    ref.invalidateSelf();
    ref.invalidate(petFosterPlacementProvider((_orgId, updated.petId)));
    return updated;
  }

  Future<FosterPlacement> acceptInvite() async {
    final token = ref.read(orgTokenProvider)!;
    final dataSource = ref.read(fosterPlacementsDataSourceProvider);
    final row = await dataSource.acceptPlacement(arg.placementId, token);
    ref.invalidateSelf();
    invalidatePlacementMutationProviders(ref.container);
    return FosterPlacement.fromJson(row);
  }

  Future<FosterPlacement> declineInvite() async {
    final token = ref.read(orgTokenProvider)!;
    final dataSource = ref.read(fosterPlacementsDataSourceProvider);
    final row = await dataSource.declinePlacement(arg.placementId, token);
    ref.invalidateSelf();
    invalidatePlacementMutationProviders(ref.container);
    return FosterPlacement.fromJson(row);
  }
}

final fosteringSessionDetailProvider =
    AsyncNotifierProvider.family<
      FosteringSessionDetailNotifier,
      FosteringSessionDetail,
      FosteringSessionDetailKey
    >(FosteringSessionDetailNotifier.new);
