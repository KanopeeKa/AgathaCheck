import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/api_base_url_provider.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/people_remote_datasource.dart';
import '../../data/models/people_contact_model.dart';
import '../../domain/entities/people_contact.dart';

final peopleRemoteDataSourceProvider = Provider<PeopleRemoteDataSource>((ref) {
  return PeopleRemoteDataSourceImpl(
    baseUrl: ref.watch(apiBaseUrlProvider),
    token: ref.watch(authProvider).accessToken,
    client: ref.watch(authHttpClientProvider),
  );
});

final peopleContactsProvider =
    AsyncNotifierProvider<PeopleContactsNotifier, List<PeopleContact>>(() {
      return PeopleContactsNotifier();
    });

class PeopleContactsNotifier extends AsyncNotifier<List<PeopleContact>> {
  @override
  Future<List<PeopleContact>> build() async {
    final ds = ref.read(peopleRemoteDataSourceProvider);
    final models = await ds.listContacts(includeInactive: true);
    return models.map((m) => m.toEntity()).toList();
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    state = previous == null ? const AsyncLoading() : AsyncData(previous);
    state = await AsyncValue.guard(() async {
      final ds = ref.read(peopleRemoteDataSourceProvider);
      final models = await ds.listContacts(includeInactive: true);
      return models.map((m) => m.toEntity()).toList();
    });
  }

  void mergeLocal(PeopleContactModel model) {
    final entity = model.toEntity();
    final current = state.valueOrNull ?? [];
    final idx = current.indexWhere((c) => c.id == entity.id);
    if (idx >= 0) {
      final next = [...current];
      next[idx] = entity;
      state = AsyncData(next);
    } else {
      state = AsyncData([...current, entity]);
    }
  }

  Future<PeopleContact> addContact(PeopleContactModel draft) async {
    final ds = ref.read(peopleRemoteDataSourceProvider);
    final created = await ds.createContact(draft);
    mergeLocal(created);
    return created.toEntity();
  }

  Future<PeopleContact> updateContactPatch(
    String id,
    Map<String, dynamic> patch,
  ) async {
    final ds = ref.read(peopleRemoteDataSourceProvider);
    final updated = await ds.updateContact(id, patch);
    mergeLocal(updated);
    ref.invalidate(peopleContactDetailProvider(id));
    return updated.toEntity();
  }

  Future<void> deleteContact(String id) async {
    final ds = ref.read(peopleRemoteDataSourceProvider);
    await ds.deleteContact(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((c) => c.id != id).toList());
  }

  PeopleContact? findByLegacyVetId(String vetId) {
    return state.valueOrNull?.where((c) => c.legacyVetId == vetId).firstOrNull;
  }
}

final peopleContactByIdProvider = Provider.family<PeopleContact?, String>((
  ref,
  id,
) {
  final async = ref.watch(peopleContactsProvider);
  return async.valueOrNull?.where((c) => c.id == id).firstOrNull;
});

/// Fetches one contact from the server and merges it into [peopleContactsProvider].
///
/// Must not `watch` the contacts list: `mergeLocal` below changes that list, which
/// would re-run this provider, fetch again and merge again — an endless refetch loop
/// that left the edit screen on its loading spinner. Mutations through
/// [PeopleContactsNotifier.updateContactPatch] invalidate this provider instead.
final peopleContactDetailProvider = FutureProvider.autoDispose
    .family<PeopleContact?, String>((ref, id) async {
      final ds = ref.read(peopleRemoteDataSourceProvider);
      try {
        final model = await ds.getContact(id);
        ref.read(peopleContactsProvider.notifier).mergeLocal(model);
        return model.toEntity();
      } catch (_) {
        return ref.read(peopleContactByIdProvider(id));
      }
    });

final peopleContactIdForLegacyVetProvider = Provider.family<String?, String>((
  ref,
  vetId,
) {
  final async = ref.watch(peopleContactsProvider);
  return async.valueOrNull
      ?.where((c) => c.legacyVetId == vetId)
      .map((c) => c.id)
      .firstOrNull;
});
