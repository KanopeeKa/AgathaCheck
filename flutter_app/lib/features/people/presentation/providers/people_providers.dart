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
    state = previous == null
        ? const AsyncLoading()
        : AsyncData(previous);
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
    return updated.toEntity();
  }

  Future<void> deleteContact(String id) async {
    final ds = ref.read(peopleRemoteDataSourceProvider);
    await ds.deleteContact(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((c) => c.id != id).toList());
  }

  PeopleContact? findByLegacyVetId(String vetId) {
    return state.valueOrNull
        ?.where((c) => c.legacyVetId == vetId)
        .firstOrNull;
  }
}

final peopleContactByIdProvider = Provider.family<PeopleContact?, String>((
  ref,
  id,
) {
  final async = ref.watch(peopleContactsProvider);
  return async.valueOrNull?.where((c) => c.id == id).firstOrNull;
});

final peopleContactDetailProvider = FutureProvider.autoDispose
    .family<PeopleContact?, String>((ref, id) async {
      final cached = ref.watch(peopleContactByIdProvider(id));
      final ds = ref.read(peopleRemoteDataSourceProvider);
      try {
        final model = await ds.getContact(id);
        ref.read(peopleContactsProvider.notifier).mergeLocal(model);
        return model.toEntity();
      } catch (_) {
        return cached;
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
