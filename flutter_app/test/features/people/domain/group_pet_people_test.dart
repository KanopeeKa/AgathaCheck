import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/people/domain/entities/pet_people.dart';
import 'package:pet_profile_app/features/people/domain/enums/relationship_kind.dart';
import 'package:pet_profile_app/features/people/domain/services/group_pet_people.dart';

PetPeople _people({
  String scope = 'full',
  List<PetRelationship> relationships = const [],
  List<HouseholdMemberSnapshot> members = const [],
}) {
  return PetPeople(
    petId: 'p1',
    petName: 'Buddy',
    scope: scope,
    owner: const PetPeopleOwner(userId: 'u-owner', displayName: 'Alex'),
    householdMembers: members,
    relationships: relationships,
  );
}

PetRelationship _rel({
  required String id,
  required String contactId,
  required RelationshipKind kind,
  required String name,
  List<String> roles = const [],
  String contactKind = 'person',
  int sortOrder = 0,
}) {
  return PetRelationship(
    id: id,
    petId: 'p1',
    contactId: contactId,
    relationshipKind: kind,
    isPrimary: true,
    active: true,
    contactKind: contactKind,
    contactName: name,
    contactRoles: roles,
    sortOrder: sortOrder,
  );
}

void main() {
  test('primary vet appears once under vets, not duplicated elsewhere', () {
    final people = _people(
      relationships: [
        _rel(
          id: 'r1',
          contactId: 'c1',
          kind: RelationshipKind.primaryVet,
          name: 'Dr Sarah Mitchell',
          roles: ['vet'],
          contactKind: 'person',
        ),
        _rel(
          id: 'r2',
          contactId: 'c2',
          kind: RelationshipKind.outOfHoursVet,
          name: 'Happy Paws',
          contactKind: 'organisation',
        ),
      ],
    );

    final grouped = groupPetPeople(people);
    expect(grouped.vets.rows, hasLength(2));
    expect(grouped.vets.rows[0].name, 'Dr Sarah Mitchell');
    expect(grouped.vets.rows[1].name, 'Happy Paws');
    expect(
      grouped.trustedCarers,
      isNull,
    );
    expect(grouped.otherProfessionals, isNull);
  });

  test('one contact in two vet slots is one row with two pills', () {
    final people = _people(
      relationships: [
        _rel(
          id: 'r1',
          contactId: 'c1',
          kind: RelationshipKind.primaryVet,
          name: 'Greenhill',
          contactKind: 'organisation',
        ),
        _rel(
          id: 'r2',
          contactId: 'c1',
          kind: RelationshipKind.outOfHoursVet,
          name: 'Greenhill',
          contactKind: 'organisation',
        ),
      ],
    );

    final grouped = groupPetPeople(people);
    expect(grouped.vets.rows, hasLength(1));
    expect(grouped.vets.rows.first.slotKinds, [
      RelationshipKind.primaryVet,
      RelationshipKind.outOfHoursVet,
    ]);
  });

  test('classifies groomer role as other professionals', () {
    final people = _people(
      relationships: [
        _rel(
          id: 'r1',
          contactId: 'c1',
          kind: RelationshipKind.other,
          name: 'Groomer Jane',
          roles: ['groomer'],
        ),
      ],
    );

    final grouped = groupPetPeople(people);
    expect(grouped.otherProfessionals?.single.name, 'Groomer Jane');
    expect(grouped.trustedCarers, isNull);
  });

  test('classifies individual vet role under vets', () {
    final people = _people(
      relationships: [
        _rel(
          id: 'r1',
          contactId: 'c1',
          kind: RelationshipKind.other,
          name: 'Mobile Vet',
          roles: ['vet'],
        ),
      ],
    );

    final grouped = groupPetPeople(people);
    expect(grouped.vets.rows.single.name, 'Mobile Vet');
  });

  test('handover at home shows owner only', () {
    final people = _people(
      scope: 'handover',
      members: [
        const HouseholdMemberSnapshot(
          userId: 'u2',
          displayName: 'Sam',
          firstName: 'Sam',
          tier: 'full_access',
          isOrganiser: false,
        ),
      ],
    );

    final grouped = groupPetPeople(people);
    expect(grouped.atHome.rows, hasLength(1));
    expect(grouped.atHome.rows.first.isOwner, isTrue);
  });

  test('vets group reports hasPrimaryVet', () {
    final empty = groupPetPeople(_people());
    expect(empty.vets.hasPrimaryVet, isFalse);

    final withVet = groupPetPeople(
      _people(
        relationships: [
          _rel(
            id: 'r1',
            contactId: 'c1',
            kind: RelationshipKind.primaryVet,
            name: 'Vet',
            contactKind: 'organisation',
          ),
        ],
      ),
    );
    expect(withVet.vets.hasPrimaryVet, isTrue);
  });
}
