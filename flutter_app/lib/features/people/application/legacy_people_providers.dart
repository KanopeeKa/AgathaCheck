import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/people_contact_model.dart';
import '../domain/entities/people_contact.dart';
import '../domain/entities/people_legacy_mapping.dart';
import 'people_commands.dart';
import 'people_providers.dart';

export 'people_commands.dart';
export 'people_providers.dart';

/// Deprecated — use [peopleRepositoryProvider].
@Deprecated('Use peopleRepositoryProvider from people.dart')
final peopleRemoteDataSourceProvider = Provider<Never>((ref) {
  throw UnsupportedError(
    'peopleRemoteDataSourceProvider removed; use peopleRepositoryProvider',
  );
});

/// Deprecated adapter over [PeopleRepository] for legacy screens.
@Deprecated('Use rosterProvider and peopleContactFromSummary')
final peopleContactsProvider =
    AsyncNotifierProvider<PeopleContactsLegacyNotifier, List<PeopleContact>>(
      PeopleContactsLegacyNotifier.new,
    );

@Deprecated('Use PeopleContactsLegacyNotifier')
typedef PeopleContactsNotifier = PeopleContactsLegacyNotifier;

class PeopleContactsLegacyNotifier extends AsyncNotifier<List<PeopleContact>> {
  @override
  Future<List<PeopleContact>> build() async {
    final repo = ref.read(peopleRepositoryProvider);
    final summaries = await repo.listContactSummaries(includeInactive: true);
    return summaries.map(peopleContactFromSummary).toList();
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    state = previous == null ? const AsyncLoading() : AsyncData(previous);
    state = await AsyncValue.guard(() async {
      final repo = ref.read(peopleRepositoryProvider);
      final summaries = await repo.listContactSummaries(includeInactive: true);
      return summaries.map(peopleContactFromSummary).toList();
    });
  }

  void mergeLocal(PeopleContactModel model) {
    final entity = model.toEntity();
    final current = state.valueOrNull ?? [];
    final idx = current.indexWhere((c) => c.id == entity.id);
    if (idx >= 0) {
      if (current[idx] == entity) return;
      final next = [...current];
      next[idx] = entity;
      state = AsyncData(next);
    } else {
      state = AsyncData([...current, entity]);
    }
  }

  Future<PeopleContact> addContact(PeopleContactModel draft) async {
    final repo = ref.read(peopleRepositoryProvider);
    final created = await repo.createContact(draft.toCreateJson());
    final entity = peopleContactFromDetail(created);
    mergeLocal(
      PeopleContactModel(
        id: entity.id,
        kind: entity.kind,
        name: entity.name,
        roles: entity.roles,
        phone: entity.phone,
        email: entity.email,
        address: entity.address,
        website: entity.website,
        privateNote: entity.privateNote,
        inactiveAt: entity.inactiveAt,
        legacyVetId: entity.legacyVetId,
        worksAtContactId: entity.worksAtContactId,
      ),
    );
    await ref.read(peopleCommandsProvider).afterContactMutation(entity.id);
    return entity;
  }

  Future<PeopleContact> updateContactPatch(
    String id,
    Map<String, dynamic> patch,
  ) async {
    final repo = ref.read(peopleRepositoryProvider);
    final updated = await repo.patchContact(id, patch);
    final entity = peopleContactFromDetail(updated);
    mergeLocal(
      PeopleContactModel(
        id: entity.id,
        kind: entity.kind,
        name: entity.name,
        roles: entity.roles,
        phone: entity.phone,
        email: entity.email,
        address: entity.address,
        website: entity.website,
        privateNote: entity.privateNote,
        inactiveAt: entity.inactiveAt,
        legacyVetId: entity.legacyVetId,
        worksAtContactId: entity.worksAtContactId,
      ),
    );
    await ref.read(peopleCommandsProvider).afterContactMutation(id);
    return entity;
  }

  Future<void> deleteContact(String id) async {
    final repo = ref.read(peopleRepositoryProvider);
    await repo.deleteContact(id);
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((c) => c.id != id).toList());
    await ref.read(peopleCommandsProvider).afterContactDelete(id);
  }

  PeopleContact? findByLegacyVetId(String vetId) {
    return state.valueOrNull?.where((c) => c.legacyVetId == vetId).firstOrNull;
  }
}

@Deprecated('Use personSummaryProvider')
final peopleContactByIdProvider = Provider.family<PeopleContact?, String>((
  ref,
  id,
) {
  final fromList = ref
      .watch(peopleContactsProvider)
      .valueOrNull
      ?.where((c) => c.id == id)
      .firstOrNull;
  if (fromList != null) return fromList;
  final summary = ref.watch(personSummaryProvider(id));
  if (summary != null) return peopleContactFromSummary(summary);
  return null;
});

@Deprecated('Use personDetailProvider')
final peopleContactDetailProvider = FutureProvider.autoDispose
    .family<PeopleContact?, String>((ref, id) async {
      final cached = ref.read(peopleContactByIdProvider(id));
      final repo = ref.read(peopleRepositoryProvider);
      try {
        final detail = await repo.fetchContactDetail(id);
        return peopleContactFromDetail(detail);
      } catch (_) {
        return cached;
      }
    });

final peopleContactIdForLegacyVetProvider = Provider.family<String?, String>((
  ref,
  vetId,
) {
  return ref
      .watch(peopleContactsProvider)
      .valueOrNull
      ?.where((c) => c.legacyVetId == vetId)
      .map((c) => c.id)
      .firstOrNull;
});
