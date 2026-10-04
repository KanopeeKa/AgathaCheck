import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/people/domain/entities/contact_summary.dart';
import 'package:pet_profile_app/features/people/domain/entities/household.dart';
import 'package:pet_profile_app/features/people/domain/entities/roster.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_group.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_kind.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_role.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_status.dart';
import 'package:pet_profile_app/features/people/domain/enums/relationship_kind.dart';
import 'package:pet_profile_app/features/people/domain/services/desk_ranking.dart';
import 'package:pet_profile_app/features/people/domain/services/roster_search.dart';
import 'package:pet_profile_app/features/people/domain/services/roster_sections.dart';

ContactSummary _contact({
  required String id,
  required String name,
  ContactGroup group = ContactGroup.carer,
  ContactStatus status = ContactStatus.active,
  List<ContactRole> roles = const [ContactRole.sitter],
  List<ContactPetLink> pets = const [],
  ContactNextAbsence? nextAbsence,
  String? legacyVetId,
}) {
  return ContactSummary(
    id: id,
    directory: const ContactDirectoryRef(type: 'personal'),
    kind: ContactKind.person,
    name: name,
    roles: roles,
    group: group,
    status: status,
    pets: pets,
    nextAbsence: nextAbsence,
    legacyVetId: legacyVetId,
  );
}

void main() {
  test('ContactSummary equality is value-based', () {
    final a = _contact(id: '1', name: 'Alex');
    final b = _contact(id: '1', name: 'Alex');
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('roster sections omit empty groups', () {
    final roster = Roster(
      households: const [],
      contacts: [
        _contact(id: 'c1', name: 'Jamie', group: ContactGroup.carer),
        _contact(
          id: 'c2',
          name: 'Greenhill',
          group: ContactGroup.professional,
          roles: const [ContactRole.vet],
        ),
      ],
      pendingInvites: const [],
    );
    final sections = buildRosterSections(roster);
    expect(sections.length, 2);
    expect(sections[0].kind.name, 'trustedCarers');
    expect(sections[1].kind.name, 'petProfessionals');
  });

  test('search ranks prefix matches higher', () {
    final contacts = [
      _contact(id: '1', name: 'Jamie Taylor'),
      _contact(id: '2', name: 'Alex Morgan'),
    ];
    final results = searchContacts(contacts, 'jam');
    expect(results.first.name, 'Jamie Taylor');
  });

  test('desk ranking prefers upcoming absence carer', () {
    final contacts = [
      _contact(id: '1', name: 'A'),
      _contact(
        id: '2',
        name: 'B',
        nextAbsence: const ContactNextAbsence(
          absenceId: 'abs-1',
          startsOn: '2026-10-10',
          endsOn: '2026-10-12',
          petIds: ['p1'],
        ),
      ),
    ];
    final ranked = rankTrustedCarerContacts(contacts);
    expect(ranked.first.id, '2');
  });

  test('vet team ranking uses linked pet counts', () {
    final contacts = [
      _contact(
        id: '1',
        name: 'Low',
        group: ContactGroup.professional,
        roles: const [ContactRole.vet],
        legacyVetId: 'v1',
      ),
      _contact(
        id: '2',
        name: 'High',
        group: ContactGroup.professional,
        roles: const [ContactRole.vet],
        legacyVetId: 'v2',
      ),
    ];
    final ranked = rankVetTeamContacts(
      contacts,
      const DeskRankingContext(linkedPetCountByLegacyVetId: {'v2': 2, 'v1': 0}),
    );
    expect(ranked.first.id, '2');
  });
}
