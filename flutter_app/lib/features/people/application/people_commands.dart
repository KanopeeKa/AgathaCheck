import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enums/relationship_kind.dart';
import 'people_providers.dart';

class PeopleCommands {
  PeopleCommands(this._ref);

  final Ref _ref;

  Future<void> refreshRoster() async {
    await _ref.read(rosterProvider.notifier).refresh();
  }

  Future<void> afterContactMutation(String contactId, {List<String>? petIds}) {
    _ref.invalidate(personDetailProvider(contactId));
    _ref.invalidate(relatedCareProvider(contactId));
    for (final petId in petIds ?? const []) {
      _ref.invalidate(petPeopleProvider(petId));
    }
    return refreshRoster();
  }

  Future<void> afterPetLinkChange(String contactId, String petId) {
    return afterContactMutation(contactId, petIds: [petId]);
  }

  Future<void> linkContactToPet({
    required String contactId,
    required String petId,
    required RelationshipKind relationshipKind,
  }) async {
    final repo = _ref.read(peopleRepositoryProvider);
    await repo.addContactPetRelationship(
      petId: petId,
      contactId: contactId,
      relationshipKind: relationshipKind,
    );
    await afterPetLinkChange(contactId, petId);
  }

  Future<void> saveContactNotes(
    String contactId, {
    String? privateNote,
    String? householdNote,
  }) async {
    final repo = _ref.read(peopleRepositoryProvider);
    final patch = <String, dynamic>{};
    if (privateNote != null) patch['private_note'] = privateNote;
    if (householdNote != null) patch['household_note'] = householdNote;
    if (patch.isEmpty) return;
    await repo.patchContact(contactId, patch);
    await afterContactMutation(contactId);
  }

  Future<void> afterContactDelete(String contactId, {List<String>? petIds}) {
    return afterContactMutation(contactId, petIds: petIds);
  }
}

final peopleCommandsProvider = Provider<PeopleCommands>(
  (ref) => PeopleCommands(ref),
);
