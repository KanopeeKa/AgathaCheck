import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/domain/entities/pet_viewer_role.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../domain/entities/pet_access.dart';
import '../../domain/entities/pet_share_access.dart';
import '../../domain/entities/share_invite.dart';
import 'sharing_providers.dart';

/// Route extra for bulk share: pet IDs or [SharePetRouteArgs].
class SharePetRouteArgs {
  const SharePetRouteArgs({required this.petIds, this.initialPetId});

  final List<String> petIds;
  final String? initialPetId;
}

class SharePetState {
  const SharePetState({
    required this.petIds,
    this.selectedPetId,
    this.accessByPet = const {},
    this.isLoading = true,
    this.error,
    this.isSendingInvite = false,
  });

  final List<String> petIds;
  final String? selectedPetId;
  final Map<String, PetShareAccess> accessByPet;
  final bool isLoading;
  final Object? error;
  final bool isSendingInvite;

  SharePetState copyWith({
    List<String>? petIds,
    String? selectedPetId,
    Map<String, PetShareAccess>? accessByPet,
    bool? isLoading,
    Object? error,
    bool? isSendingInvite,
    bool clearError = false,
  }) {
    return SharePetState(
      petIds: petIds ?? this.petIds,
      selectedPetId: selectedPetId ?? this.selectedPetId,
      accessByPet: accessByPet ?? this.accessByPet,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSendingInvite: isSendingInvite ?? this.isSendingInvite,
    );
  }
}

final sharePetNotifierProvider = StateNotifierProvider.autoDispose
    .family<SharePetNotifier, SharePetState, List<String>>((ref, petIds) {
      return SharePetNotifier(ref, petIds);
    });

class SharePetNotifier extends StateNotifier<SharePetState> {
  SharePetNotifier(this._ref, List<String> petIds)
    : super(
        SharePetState(
          petIds: petIds,
          selectedPetId: petIds.isNotEmpty ? petIds.first : null,
        ),
      ) {
    _load();
  }

  final Ref _ref;

  Future<String?> _getToken() async {
    return _ref.read(authProvider.notifier).getValidAccessToken();
  }

  Future<void> _load() async {
    if (state.petIds.isEmpty) {
      state = state.copyWith(isLoading: false, accessByPet: {});
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final token = await _getToken();
      if (token == null) {
        state = state.copyWith(isLoading: false, accessByPet: {});
        return;
      }
      final repo = _ref.read(sharingRepositoryProvider);
      final rows = await repo.listAccessForPets(state.petIds, token);
      final byPet = {for (final row in rows) row.petId: row};
      state = state.copyWith(isLoading: false, accessByPet: byPet);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e, accessByPet: {});
    }
  }

  void selectPet(String petId) {
    if (!state.petIds.contains(petId)) return;
    state = state.copyWith(selectedPetId: petId);
  }

  Future<void> refresh() async {
    await _load();
  }

  Future<CreateShareInviteResult?> sendInvite({
    required String inviteeEmail,
    required PetAccessRole role,
    String? locale,
  }) async {
    state = state.copyWith(isSendingInvite: true, clearError: true);
    try {
      final token = await _getToken();
      if (token == null) throw Exception('Not authenticated');
      final repo = _ref.read(sharingRepositoryProvider);
      final result = await repo.createInvite(
        inviteeEmail: inviteeEmail,
        petIds: state.petIds,
        role: role.toWire(),
        token: token,
        locale: locale,
      );
      await refresh();
      state = state.copyWith(isSendingInvite: false);
      return result;
    } catch (e) {
      state = state.copyWith(isSendingInvite: false, error: e);
      rethrow;
    }
  }

  Future<void> cancelInvite(String inviteId) async {
    final token = await _getToken();
    if (token == null) return;
    final repo = _ref.read(sharingRepositoryProvider);
    await repo.cancelInvite(inviteId, token);
    await refresh();
  }

  List<ShareInvite> pendingInvitesForPet(String petId) {
    return state.accessByPet[petId]?.pendingInvites ?? const [];
  }

  List<PetAccess> accessForPet(String petId) {
    return state.accessByPet[petId]?.access ?? const [];
  }
}

/// Resolves viewer role for a pet on the share screen.
PetViewerRole sharePetViewerRole(Pet pet) {
  if (pet.organizationId != null) return PetViewerRole.organization;
  if (pet.isFoster) return PetViewerRole.fosterCarer;
  if (pet.accessRole == PetAccessRole.coParent) return PetViewerRole.coParent;
  if (pet.isShared) return PetViewerRole.sharedCarer;
  return PetViewerRole.guardian;
}

/// Loads [Pet] instances for the given IDs from the cached pet list.
final sharePetListProvider = Provider.autoDispose
    .family<AsyncValue<List<Pet>>, List<String>>((ref, petIds) {
      final petsAsync = ref.watch(allPetsIncludingOrgProvider);
      return petsAsync.whenData((pets) {
        final byId = {for (final pet in pets) pet.id: pet};
        return petIds.map((id) => byId[id]).whereType<Pet>().toList();
      });
    });
