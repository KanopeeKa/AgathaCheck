import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/household.dart';
import '../domain/entities/pet_people.dart';
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

  Future<void> patchContact(
    String contactId,
    Map<String, dynamic> patch,
  ) async {
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
    final byId = {for (final r in all.where((r) => r.active)) r.id: r};
    final emergencies = <PetRelationship>[];
    for (final id in orderedRelationshipIds) {
      final row = byId[id];
      if (row != null &&
          row.relationshipKind == RelationshipKind.emergencyContact) {
        emergencies.add(row);
      }
    }
    for (final row in all) {
      if (!row.active) continue;
      if (row.relationshipKind != RelationshipKind.emergencyContact) continue;
      if (emergencies.any((e) => e.id == row.id)) continue;
      emergencies.add(row);
    }
    final payload = <Map<String, dynamic>>[];
    for (final row in all.where((r) => r.active)) {
      if (row.relationshipKind == RelationshipKind.emergencyContact) continue;
      payload.add(_relationshipWire(row));
    }
    for (final row in emergencies) {
      payload.add(_relationshipWire(row));
    }
    await _repo.replacePetRelationships(petId, payload);
    await afterPetLinkChange(contactId, petId);
  }

  Map<String, dynamic> _relationshipWire(PetRelationship r) => {
    'id': r.id,
    'contact_id': r.contactId,
    'relationship_kind': r.relationshipKind.wireValue,
    'is_primary': r.isPrimary,
    'active': r.active,
  };

  Future<Household> createHousehold(
    String name, {
    List<String> petIds = const [],
  }) async {
    final household = await _households.createHousehold(name, petIds: petIds);
    await _invalidateHouseholds();
    return household;
  }

  Future<Household> renameHousehold({
    required String householdId,
    required String name,
  }) async {
    final household = await _households.renameHousehold(
      householdId: householdId,
      name: name,
    );
    await _invalidateHouseholds();
    return household;
  }

  Future<void> setHouseholdPets({
    required String householdId,
    required List<String> petIds,
  }) async {
    await _households.setHouseholdPets(
      householdId: householdId,
      petIds: petIds,
    );
    await _invalidateHouseholds();
  }

  Future<void> createHouseholdInvite({
    required String householdId,
    required String inviteeEmail,
    String? contactId,
    String accessTier = 'full_access',
    bool isOrganiser = false,
  }) async {
    await _households.createHouseholdInvite(
      householdId: householdId,
      inviteeEmail: inviteeEmail,
      contactId: contactId,
      accessTier: accessTier,
      isOrganiser: isOrganiser,
    );
    await refreshRoster();
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

  Future<void> acceptHouseholdInvite(String code) async {
    await _households.acceptHouseholdInvite(code);
    await _invalidateHouseholds();
  }

  Future<void> declineHouseholdInvite(String code) async {
    await _households.declineHouseholdInvite(code);
  }

  Future<void> _invalidateHouseholds() async {
    _ref.invalidate(peopleHouseholdsProvider);
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
