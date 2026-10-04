import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  Future<void> afterContactDelete(String contactId, {List<String>? petIds}) {
    return afterContactMutation(contactId, petIds: petIds);
  }
}

final peopleCommandsProvider = Provider<PeopleCommands>(
  (ref) => PeopleCommands(ref),
);
