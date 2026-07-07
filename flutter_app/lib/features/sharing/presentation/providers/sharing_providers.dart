import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../pet_profile/presentation/providers/pet_providers.dart';
import '../../data/datasources/sharing_remote_datasource.dart';
import '../../data/repositories/sharing_repository_impl.dart';
import '../../domain/entities/pet_access.dart';
import '../../domain/entities/share_link.dart';
import '../../domain/repositories/sharing_repository.dart';

final sharingDataSourceProvider = Provider<SharingRemoteDataSource>((ref) {
  return SharingRemoteDataSource(
    // Route through the shared base URL ('/backend' on web) instead of the
    // datasource's own default, so all features hit one consistent prefix.
    baseUrl: ref.watch(apiBaseUrlProvider),
    client: ref.watch(authHttpClientProvider),
  );
});

/// The seam the presentation layer depends on; override in tests with a fake.
final sharingRepositoryProvider = Provider<SharingRepository>((ref) {
  return SharingRepositoryImpl(ref.watch(sharingDataSourceProvider));
});

class PendingShare {
  final String id;
  final String petId;
  final String petName;
  final String petSpecies;
  final String petBreed;
  final String? petPhotoPath;
  final int? petColorValue;
  final String guardianName;
  final String? invitedBy;
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
      id: json['id']?.toString() ?? '',
      petId: json['pet_id']?.toString() ?? '',
      petName: (json['pet_name'] ?? '').toString(),
      petSpecies: (json['pet_species'] ?? '').toString(),
      petBreed: (json['pet_breed'] ?? '').toString(),
      petPhotoPath: json['pet_photo_path']?.toString(),
      petColorValue: json['pet_color_value'] is int
          ? json['pet_color_value'] as int
          : int.tryParse(json['pet_color_value']?.toString() ?? ''),
      guardianName: (json['guardian_name'] ?? '').toString(),
      invitedBy: json['invited_by']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class PendingSharesNotifier extends AsyncNotifier<List<PendingShare>> {
  @override
  Future<List<PendingShare>> build() async {
    final token = await ref.read(authProvider.notifier).getValidAccessToken();
    if (token == null) return [];
    final repo = ref.read(sharingRepositoryProvider);
    final rawList = await repo.getPendingShares(token);
    return rawList.map((m) => PendingShare.fromJson(m)).toList();
  }

  Future<void> acceptShare(String petId, {String? organizationId}) async {
    final token = await ref.read(authProvider.notifier).getValidAccessToken();
    if (token == null) return;
    final repo = ref.read(sharingRepositoryProvider);
    await repo.acceptPendingShare(petId, token, organizationId: organizationId);
    ref.invalidateSelf();
    // Invalidate then await so the accepted shared pet appears as soon as the
    // pending card disappears (not on a later manual refresh).
    ref.invalidate(allPetsIncludingOrgProvider);
    await ref.read(allPetsIncludingOrgProvider.future);
  }

  Future<void> declineShare(String petId) async {
    final token = await ref.read(authProvider.notifier).getValidAccessToken();
    if (token == null) return;
    final repo = ref.read(sharingRepositoryProvider);
    await repo.declinePendingShare(petId, token);
    ref.invalidateSelf();
  }
}

final pendingSharesProvider =
    AsyncNotifierProvider<PendingSharesNotifier, List<PendingShare>>(
      PendingSharesNotifier.new,
    );

class HiddenSharedPet {
  final String id;
  final String name;
  final String species;
  final String photoUrl;
  final String? organizationId;
  final String? organizationName;

  const HiddenSharedPet({
    required this.id,
    required this.name,
    required this.species,
    required this.photoUrl,
    this.organizationId,
    this.organizationName,
  });

  factory HiddenSharedPet.fromJson(Map<String, dynamic> json) {
    return HiddenSharedPet(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      species: json['species']?.toString() ?? '',
      photoUrl: (json['photo_url'] ?? json['photo_path'] ?? '').toString(),
      organizationId: json['organization_id']?.toString(),
      organizationName: json['organization_name']?.toString(),
    );
  }
}

class HiddenSharedPetsNotifier extends AsyncNotifier<List<HiddenSharedPet>> {
  @override
  Future<List<HiddenSharedPet>> build() async {
    final token = await ref.read(authProvider.notifier).getValidAccessToken();
    if (token == null) return [];
    final repo = ref.read(sharingRepositoryProvider);
    final rawList = await repo.getHiddenSharedPets(token);
    return rawList.map((m) => HiddenSharedPet.fromJson(m)).toList();
  }

  Future<void> hideSharedPet(String petId) async {
    final token = await ref.read(authProvider.notifier).getValidAccessToken();
    if (token == null) return;
    final repo = ref.read(sharingRepositoryProvider);
    await repo.hideSharedPet(petId, token, hidden: true);
    ref.invalidateSelf();
    ref.invalidate(allPetsIncludingOrgProvider);
  }

  Future<void> unhideSharedPet(String petId) async {
    final token = await ref.read(authProvider.notifier).getValidAccessToken();
    if (token == null) return;
    final repo = ref.read(sharingRepositoryProvider);
    await repo.hideSharedPet(petId, token, hidden: false);
    ref.invalidateSelf();
    ref.invalidate(allPetsIncludingOrgProvider);
  }
}

final hiddenSharedPetsProvider =
    AsyncNotifierProvider<HiddenSharedPetsNotifier, List<HiddenSharedPet>>(
      HiddenSharedPetsNotifier.new,
    );

final petAccessProvider = FutureProvider.family<List<PetAccess>, String>((
  ref,
  petId,
) async {
  final token = await ref.read(authProvider.notifier).getValidAccessToken();
  if (token == null) return [];
  final repo = ref.watch(sharingRepositoryProvider);
  return repo.getAccess(petId, token);
});

final petAccessNotifierProvider =
    StateNotifierProvider.family<
      PetAccessNotifier,
      AsyncValue<List<PetAccess>>,
      String
    >((ref, petId) {
      return PetAccessNotifier(ref, petId);
    });

class PetAccessNotifier extends StateNotifier<AsyncValue<List<PetAccess>>> {
  final Ref _ref;
  final String petId;

  PetAccessNotifier(this._ref, this.petId) : super(const AsyncValue.loading()) {
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
      final repo = _ref.read(sharingRepositoryProvider);
      final list = await repo.getAccess(petId, token);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await _load();
  }

  Future<void> updateRole(String userId, PetAccessRole role) async {
    final token = await _getToken();
    if (token == null) return;
    final repo = _ref.read(sharingRepositoryProvider);
    final roleStr = role == PetAccessRole.guardian ? 'guardian' : 'shared';
    await repo.updateRole(petId, userId, roleStr, token);
    await refresh();
  }

  Future<void> removeAccess(String userId) async {
    final token = await _getToken();
    if (token == null) return;
    final repo = _ref.read(sharingRepositoryProvider);
    await repo.removeAccess(petId, userId, token);
    await refresh();
    _ref.invalidate(petShareLinksNotifierProvider(petId));
  }

  Future<void> transferOwnership({
    required String recipientEmail,
    required String confirmationName,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');
    final repo = _ref.read(sharingRepositoryProvider);
    await repo.transferOwnership(
      petId,
      recipientEmail: recipientEmail,
      confirmationName: confirmationName,
      token: token,
    );
    _ref.invalidate(allPetsIncludingOrgProvider);
  }
}

final petShareLinksNotifierProvider =
    StateNotifierProvider.family<
      PetShareLinksNotifier,
      AsyncValue<List<ShareLink>>,
      String
    >((ref, petId) {
      return PetShareLinksNotifier(ref, petId);
    });

class PetShareLinksNotifier extends StateNotifier<AsyncValue<List<ShareLink>>> {
  final Ref _ref;
  final String petId;

  PetShareLinksNotifier(this._ref, this.petId)
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
      final repo = _ref.read(sharingRepositoryProvider);
      final list = await repo.getShareLinks(petId, token);
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await _load();
  }

  Future<void> deleteLink(String linkId) async {
    final token = await _getToken();
    if (token == null) return;
    final repo = _ref.read(sharingRepositoryProvider);
    await repo.deleteShareLink(linkId, token);
    await refresh();
  }

  Future<String> createLink() async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated');
    final repo = _ref.read(sharingRepositoryProvider);
    final code = await repo.createShare(petId, {}, token);
    await refresh();
    return code;
  }
}

Future<void> stopFollowingPet(WidgetRef ref, String petId) async {
  final token = await ref.read(authProvider.notifier).getValidAccessToken();
  if (token == null) return;
  final repo = ref.read(sharingRepositoryProvider);
  await repo.stopFollowing(petId, token);
  ref.invalidate(allPetsIncludingOrgProvider);
}
