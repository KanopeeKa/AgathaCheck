import '../entities/pet_people.dart';
import '../entities/pet_people_grouped.dart';
import '../enums/relationship_kind.dart';
import 'pet_people_slots.dart';

const _vetRoles = {'vet', 'vet_nurse'};
const _otherProRoles = {
  'groomer',
  'trainer',
  'behaviourist',
  'boarding',
};

/// Pure placement for D-039 / D-040. Legacy lists in [pet_people_grouping.dart]
/// stay until the pet profile section migrates (P2b).
PetPeopleGroupedSection groupPetPeople(PetPeople people) {
  final aggregates = _contactAggregates(people);
  final vetRows = <String>[];
  final emergencyRows = <String>[];
  final carerRows = <String>[];
  final proRows = <String>[];

  for (final entry in aggregates.entries) {
    final placement = _placementFor(entry.value);
    switch (placement) {
      case _Placement.vets:
        vetRows.add(entry.key);
      case _Placement.emergency:
        emergencyRows.add(entry.key);
      case _Placement.trustedCarers:
        carerRows.add(entry.key);
      case _Placement.otherProfessionals:
        proRows.add(entry.key);
    }
  }

  final hasPrimaryVet = aggregates.values.any(
    (a) => a.hasKind(RelationshipKind.primaryVet),
  );

  final vetOrdered = _orderVets(aggregates, vetRows);
  final emergencyOrdered = _orderEmergency(aggregates, emergencyRows);
  final carerOrdered = _orderByName(aggregates, carerRows);
  final proOrdered = _orderByName(aggregates, proRows);

  return PetPeopleGroupedSection(
    vets: PetPeopleVetsGroup(
      hasPrimaryVet: hasPrimaryVet,
      rows: vetOrdered
          .map((id) => _toContactRow(aggregates[id]!))
          .toList(growable: false),
    ),
    emergencyContacts: emergencyOrdered.isEmpty
        ? null
        : emergencyOrdered
            .map((id) => _toContactRow(aggregates[id]!))
            .toList(growable: false),
    atHome: PetPeopleAtHomeGroup(rows: _atHomeRows(people)),
    trustedCarers: carerOrdered.isEmpty
        ? null
        : carerOrdered
            .map((id) => _toContactRow(aggregates[id]!))
            .toList(growable: false),
    otherProfessionals: proOrdered.isEmpty
        ? null
        : proOrdered
            .map((id) => _toContactRow(aggregates[id]!))
            .toList(growable: false),
  );
}

class _ContactAggregate {
  _ContactAggregate({required this.id, required this.relationships});

  final String id;
  final List<PetRelationship> relationships;

  String get name => relationships.first.contactName;
  String? get phone => relationships.first.contactPhone;
  String get contactKind => relationships.first.contactKind;
  List<String> get roles => relationships.first.contactRoles;

  bool hasKind(RelationshipKind kind) =>
      relationships.any((r) => r.relationshipKind == kind);

  int minSortOrder(RelationshipKind kind) {
    var min = 1 << 30;
    for (final r in relationships) {
      if (r.relationshipKind != kind) continue;
      if (r.sortOrder < min) min = r.sortOrder;
    }
    return min == (1 << 30) ? 0 : min;
  }

  List<RelationshipKind> slotKinds() {
    const order = [
      RelationshipKind.primaryVet,
      RelationshipKind.outOfHoursVet,
      RelationshipKind.emergencyContact,
    ];
    final kinds = <RelationshipKind>[];
    for (final kind in order) {
      if (hasKind(kind)) kinds.add(kind);
    }
    return kinds;
  }
}

enum _Placement { vets, emergency, trustedCarers, otherProfessionals }

Map<String, _ContactAggregate> _contactAggregates(PetPeople people) {
  final map = <String, List<PetRelationship>>{};
  for (final r in people.relationships) {
    if (!petRelationshipIsVisible(r)) continue;
    map.putIfAbsent(r.contactId, () => []).add(r);
  }
  return map.map(
    (id, rels) => MapEntry(id, _ContactAggregate(id: id, relationships: rels)),
  );
}

_Placement _placementFor(_ContactAggregate contact) {
  if (contact.hasKind(RelationshipKind.primaryVet) ||
      contact.hasKind(RelationshipKind.outOfHoursVet) ||
      contact.roles.any(_vetRoles.contains)) {
    return _Placement.vets;
  }
  if (contact.hasKind(RelationshipKind.emergencyContact)) {
    return _Placement.emergency;
  }
  if (contact.contactKind == 'organisation' ||
      contact.roles.any(_otherProRoles.contains)) {
    return _Placement.otherProfessionals;
  }
  if (contact.contactKind == 'person') {
    return _Placement.trustedCarers;
  }
  return _Placement.otherProfessionals;
}

List<String> _orderVets(Map<String, _ContactAggregate> aggregates, List<String> ids) {
  String? primaryId;
  String? oohId;
  final rest = <String>[];

  for (final id in ids) {
    final a = aggregates[id]!;
    if (a.hasKind(RelationshipKind.primaryVet)) {
      primaryId ??= id;
    } else if (a.hasKind(RelationshipKind.outOfHoursVet)) {
      oohId ??= id;
    } else {
      rest.add(id);
    }
  }

  // Contact in both primary and ooh slots: keep single id at primary position.
  if (primaryId != null && oohId == primaryId) {
    oohId = null;
  }

  rest.sort((a, b) => aggregates[a]!.name.compareTo(aggregates[b]!.name));

  return [
    if (primaryId != null) primaryId,
    if (oohId != null && oohId != primaryId) oohId,
    ...rest.where((id) => id != primaryId && id != oohId),
  ];
}

List<String> _orderEmergency(
  Map<String, _ContactAggregate> aggregates,
  List<String> ids,
) {
  final sorted = [...ids];
  sorted.sort((a, b) {
    final ao = aggregates[a]!.minSortOrder(RelationshipKind.emergencyContact);
    final bo = aggregates[b]!.minSortOrder(RelationshipKind.emergencyContact);
    if (ao != bo) return ao.compareTo(bo);
  return aggregates[a]!.name.toLowerCase().compareTo(
      aggregates[b]!.name.toLowerCase(),
    );
  });
  return sorted;
}

List<String> _orderByName(
  Map<String, _ContactAggregate> aggregates,
  List<String> ids,
) {
  final sorted = [...ids];
  sorted.sort(
    (a, b) => aggregates[a]!.name.toLowerCase().compareTo(
      aggregates[b]!.name.toLowerCase(),
    ),
  );
  return sorted;
}

PetPeopleGroupedContactRow _toContactRow(_ContactAggregate contact) {
  return PetPeopleGroupedContactRow(
    contactId: contact.id,
    name: contact.name,
    contactKind: contact.contactKind,
    contactRoles: List.unmodifiable(contact.roles),
    slotKinds: contact.slotKinds(),
    phone: contact.phone,
    emergencySortOrder: contact.minSortOrder(RelationshipKind.emergencyContact),
  );
}

List<PetPeopleGroupedMemberRow> _atHomeRows(PetPeople people) {
  final ownerId = people.owner.userId;
  final ownerPhoto = people.householdMembers
      .where((m) => m.userId == ownerId)
      .map((m) => m.photoUrl)
      .firstWhere((p) => p != null, orElse: () => null);

  final ownerRow = PetPeopleGroupedMemberRow(
    userId: ownerId,
    displayName: people.owner.displayName,
    isOwner: true,
    tier: _ownerMember(people, ownerId)?.tier ?? '',
    isOrganiser: _ownerMember(people, ownerId)?.isOrganiser ?? false,
    photoUrl: ownerPhoto,
  );

  if (people.scope == 'handover') {
    return [ownerRow];
  }

  final memberRows = <PetPeopleGroupedMemberRow>[];
  for (final member in people.householdMembers) {
    if (member.userId == ownerId) continue;
    memberRows.add(
      PetPeopleGroupedMemberRow(
        userId: member.userId,
        displayName: member.displayName,
        isOwner: false,
        tier: member.tier,
        isOrganiser: member.isOrganiser,
        photoUrl: member.photoUrl,
      ),
    );
  }
  return [ownerRow, ...memberRows];
}

HouseholdMemberSnapshot? _ownerMember(PetPeople people, String ownerId) {
  for (final m in people.householdMembers) {
    if (m.userId == ownerId) return m;
  }
  return null;
}
