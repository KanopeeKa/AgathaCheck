import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../data/datasources/sharing_remote_datasource.dart';
import '../../domain/entities/pet_access.dart';

final sharingDataSourceProvider = Provider<SharingRemoteDataSource>((ref) {
  return SharingRemoteDataSource();
});

class PendingShare {
  final int id;
  final String petId;
  final String petName;
  final String petSpecies;
  final String petBreed;
  final String? petPhotoPath;
  final int? petColorValue;
  final String guardianName;
  final int? invitedBy;
  final DateTime? createdAt;

  const PendingShare({
    required this.id,
    required this.petId,
    required this.petName,
    required this.petSpecies,
    required this.petBreed,
    this.petPhotoPath,
    this.petColorValue,
    required this.guardianName,
    this.invitedBy,
    this.createdAt,
  });

  factory PendingShare.fromJson(Map<String, dynamic> json) {
    return PendingShare(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      petId: json['pet_id']?.toString() ?? '',
      petName: (json['pet_name'] ?? '').toString(),
      petSpecies: (json['pet_species'] ?? '').toString(),
      petBreed: (json['pet_breed'] ?? '').toString(),
      petPhotoPath: json['pet_photo_path']?.toString(),
      petColorValue: json['pet_color_value'] is int ? json['pet_color_value'] as int : int.tryParse(json['pet_color_value']?.toString() ?? ''),
      guardianName: (json['guardian_name'] ?? '').toString(),
      invitedBy: json['invited_by'] is int ? json['invited_by'] as int : int.tryParse(json['invited_by']?.toString() ?? ''),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class PendingSharesNotifier extends AsyncNotifier<List<PendingShare>> {
  @override
  Future<List<PendingShare>> build() async {
    final token = await ref.read(authProvider.notifier).getValidAccessToken();
    if (token == null) return [];
    final ds = ref.read(sharingDataSourceProvider);
    final rawList = await ds.getPendingShares(token);
    return rawList.map((m) => PendingShare.fromJson(m)).toList();
  }

  Future<void> acceptShare(String petId, {int? organizationId}) async {
    final token = await ref.read(authProvider.notifier).getValidAccessToken();
    if (token == null) return;
    final ds = ref.read(sharingDataSourceProvider);
    await ds.acceptPendingShare(petId, token, organizationId: organizationId);
    ref.invalidateSelf();
    ref.invalidate(allPetsIncludingOrgProvider);
  }

  Future<void> declineShare(String petId) async {
    final token = await ref.read(authProvider.notifier).getValidAccessToken();
    if (token == null) return;
    final ds = ref.read(sharingDataSourceProvider);
    await ds.declinePendingShare(petId, token);
    ref.invalidateSelf();
  }
}

final pendingSharesProvider =
    AsyncNotifierProvider<PendingSharesNotifier, List<PendingShare>>(
        PendingSharesNotifier.new);

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
