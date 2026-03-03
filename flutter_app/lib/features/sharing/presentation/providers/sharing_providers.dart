import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/sharing_remote_datasource.dart';
import '../../domain/entities/pet_access.dart';

final sharingDataSourceProvider = Provider<SharingRemoteDataSource>((ref) {
  return SharingRemoteDataSource();
});

final petAccessProvider =
    FutureProvider.family<List<PetAccess>, String>((ref, petId) async {
  final token = await ref.read(authProvider.notifier).getValidAccessToken();
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

  Future<String?> _getToken() async {
    return _ref.read(authProvider.notifier).getValidAccessToken();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final token = await _getToken();
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
    final token = await _getToken();
    if (token == null) return;
    final ds = _ref.read(sharingDataSourceProvider);
    final roleStr = role == PetAccessRole.guardian ? 'guardian' : 'shared';
    await ds.updateRole(petId, userId, roleStr, token);
    await refresh();
  }

  Future<void> removeAccess(int userId) async {
    final token = await _getToken();
    if (token == null) return;
    final ds = _ref.read(sharingDataSourceProvider);
    await ds.removeAccess(petId, userId, token);
    await refresh();
  }
}
