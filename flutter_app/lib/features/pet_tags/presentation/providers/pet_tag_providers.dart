import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import '../../data/datasources/pet_tag_remote_datasource.dart';
import '../../data/repositories/pet_tag_repository_impl.dart';
import '../../domain/entities/pet_tag.dart';
import '../../domain/repositories/pet_tag_repository.dart';

final petTagDataSourceProvider = Provider<PetTagRemoteDataSource>((ref) {
  return PetTagRemoteDataSourceImpl(
    baseUrl: ref.watch(apiBaseUrlProvider),
    client: ref.watch(authHttpClientProvider),
  );
});

PetTagRepository _petTagRepository(Ref ref) {
  final auth = ref.read(authProvider);
  if (auth.accessToken == null) {
    throw StateError('Not authenticated');
  }
  return PetTagRepositoryImpl(
    ref.read(petTagDataSourceProvider),
    () => auth.accessToken!,
  );
}

final petTagListProvider =
    AsyncNotifierProvider<PetTagListNotifier, List<PetTag>>(
      PetTagListNotifier.new,
    );

class PetTagListNotifier extends AsyncNotifier<List<PetTag>> {
  @override
  Future<List<PetTag>> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.isLoggedIn) return [];
    return _repo().listTags();
  }

  PetTagRepository _repo() => _petTagRepository(ref);

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(build);
  }

  Future<PetTag> createTag(String name) async {
    final created = await _repo().createTag(name);
    await refresh();
    return created;
  }

  Future<void> renameTag(String tagId, String name) async {
    await _repo().renameTag(tagId, name);
    await refresh();
  }

  Future<void> deleteTag(String tagId) async {
    await _repo().deleteTag(tagId);
    await refresh();
  }

  Future<void> assignTag(String petId, String tagId) async {
    await _repo().assignTag(petId, tagId);
    await refresh();
  }

  Future<void> unassignTag(String petId, String tagId) async {
    await _repo().unassignTag(petId, tagId);
    await refresh();
  }
}

/// Session-local tag filter state for `/pc/pets`.
class PetTagFilterState {
  const PetTagFilterState({
    this.selectedTagIds = const {},
    this.matchMode = PetTagMatchMode.any,
  });

  final Set<String> selectedTagIds;
  final PetTagMatchMode matchMode;

  PetTagFilterState copyWith({
    Set<String>? selectedTagIds,
    PetTagMatchMode? matchMode,
  }) => PetTagFilterState(
    selectedTagIds: selectedTagIds ?? this.selectedTagIds,
    matchMode: matchMode ?? this.matchMode,
  );
}

class PetTagFilterNotifier extends Notifier<PetTagFilterState> {
  @override
  PetTagFilterState build() => const PetTagFilterState();

  void updateSelections(Set<String> selectedTagIds) {
    state = state.copyWith(selectedTagIds: selectedTagIds);
  }

  void updateMatchMode(PetTagMatchMode matchMode) {
    state = state.copyWith(matchMode: matchMode);
  }
}

final petTagFilterProvider =
    NotifierProvider<PetTagFilterNotifier, PetTagFilterState>(
      PetTagFilterNotifier.new,
    );
