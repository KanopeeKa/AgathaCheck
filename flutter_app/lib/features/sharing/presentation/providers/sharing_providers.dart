import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/sharing_remote_datasource.dart';
import '../../domain/entities/pet_access.dart';

final sharingDataSourceProvider = Provider<SharingRemoteDataSource>((ref) {
  return SharingRemoteDataSource();
});

final petAccessProvider =
    FutureProvider.family<List<PetAccess>, String>((ref, petId) async {
  final authState = ref.watch(authProvider);
  final token = authState.accessToken;
  if (token == null) return [];
  final ds = ref.watch(sharingDataSourceProvider);
  return ds.getAccess(petId, token);
});

final petAccessNotifierProvider = StateNotifierProvider.family<
    PetAccessNotifier, AsyncValue<List<PetAccess>>, String>((ref, petId) {
  return PetAccessNotifier(ref, petId);
});

class PetAccessNotifier extends StateNotifier<AsyncValue<List<PetAccess>>> {
  final Ref _ref;
  final String petId;

  PetAccessNotifier(this._ref, this.petId)
      : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final authState = _ref.read(authProvider);
      final token = authState.accessToken;
      if (token == null) {
        state = const AsyncValue.data([]);
        return;
      }
      final ds = _ref.read(sharingDataSourceProvider);
      final list = await ds.getAccess(petId, token);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await _load();
  }

  Future<void> updateRole(int userId, PetAccessRole role) async {
    final authState = _ref.read(authProvider);
    final token = authState.accessToken;
    if (token == null) return;
    final ds = _ref.read(sharingDataSourceProvider);
    final roleStr = role == PetAccessRole.guardian ? 'guardian' : 'shared';
    await ds.updateRole(petId, userId, roleStr, token);
    await refresh();
  }

  Future<void> removeAccess(int userId) async {
    final authState = _ref.read(authProvider);
    final token = authState.accessToken;
    if (token == null) return;
    final ds = _ref.read(sharingDataSourceProvider);
    await ds.removeAccess(petId, userId, token);
    await refresh();
  }
}
