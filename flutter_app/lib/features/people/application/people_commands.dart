import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enums/relationship_kind.dart';
import '../domain/repositories/people_repository.dart';
import 'people_api_exception.dart';
import 'people_providers.dart';

class PeopleCommands {
  PeopleCommands(this._ref);

  final Ref _ref;

  PeopleRepository get _repo => _ref.read(peopleRepositoryProvider);
  HouseholdsRepository get _households =>
      _ref.read(householdsRepositoryProvider);

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
    await _repo.addContactPetRelationship(
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
    final patch = <String, dynamic>{};
    if (privateNote != null) patch['private_note'] = privateNote;
    if (householdNote != null) patch['household_note'] = householdNote;
    if (patch.isEmpty) return;
    await _repo.patchContact(contactId, patch);
    await afterContactMutation(contactId);
  }

  Future<void> patchContact(String contactId, Map<String, dynamic> patch) async {
    if (patch.isEmpty) return;
    await _repo.patchContact(contactId, patch);
    await afterContactMutation(contactId);
  }

  Future<void> deleteContact(String contactId) async {
    await _repo.deleteContact(contactId);
    await afterContactDelete(contactId);
  }

  Future<void> afterContactDelete(String contactId, {List<String>? petIds}) {
    return afterContactMutation(contactId, petIds: petIds);
  }

  Future<void> setPetSlot({
    required String contactId,
    required String petId,
    required RelationshipKind slotKind,
    required String? slotContactId,
  }) async {
    await _repo.setPetRelationshipSlot(
      petId: petId,
      slotKind: slotKind,
      contactId: slotContactId,
    );
    await afterPetLinkChange(contactId, petId);
  }

  Future<void> removePetRelationship({
    required String contactId,
    required String petId,
    required String relationshipId,
  }) async {
    await _repo.removePetRelationship(
      petId: petId,
      relationshipId: relationshipId,
    );
    await afterPetLinkChange(contactId, petId);
  }

  Future<void> reorderEmergencyContacts({
    required String contactId,
    required String petId,
    required List<String> orderedRelationshipIds,
  }) async {
    final all = await _repo.fetchPetRelationships(petId);
    final payload = all
        .where((r) => r.active)
        .map(
          (r) => {
            'id': r.id,
            'contact_id': r.contactId,
            'relationship_kind': r.relationshipKind.wireValue,
            'is_primary': r.isPrimary,
            'active': r.active,
          },
        )
        .toList();
    await _repo.replacePetRelationships(petId, payload);
    await afterPetLinkChange(contactId, petId);
  }

  Future<void> revokeHouseholdInvite({
    required String householdId,
    required String inviteId,
  }) async {
    await _households.revokeHouseholdInvite(
      householdId: householdId,
      inviteId: inviteId,
    );
    await refreshRoster();
  }

  Future<void> removeHouseholdMember({
    required String householdId,
    required String memberUserId,
    bool removeAllAccessToMyPets = false,
    String? successorUserId,
  }) async {
    await _households.removeHouseholdMember(
      householdId: householdId,
      memberUserId: memberUserId,
      removeAllAccessToMyPets: removeAllAccessToMyPets,
      successorUserId: successorUserId,
    );
    await refreshRoster();
  }

  Future<HouseholdMemberRemovalPreview> memberRemovalPreview({
    required String householdId,
    required String memberUserId,
  }) {
    return _households.fetchMemberRemovalPreview(
      householdId: householdId,
      memberUserId: memberUserId,
    );
  }
}

final peopleCommandsProvider = Provider<PeopleCommands>(
  (ref) => PeopleCommands(ref),
);

PeopleApiException? asPeopleApiException(Object error) {
  if (error is PeopleApiException) return error;
  return null;
}
