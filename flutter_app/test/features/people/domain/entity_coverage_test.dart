import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/people/domain/entities/contact_detail.dart';
import 'package:pet_profile_app/features/people/domain/entities/contact_summary.dart';
import 'package:pet_profile_app/features/people/domain/entities/pet_people.dart';
import 'package:pet_profile_app/features/people/domain/entities/roster.dart';
import 'package:pet_profile_app/features/people/domain/entities/contact_usage.dart';
import 'package:pet_profile_app/features/people/domain/entities/household.dart';
import 'package:pet_profile_app/features/people/domain/entities/household_invite.dart';
import 'package:pet_profile_app/features/people/domain/entities/person.dart';
import 'package:pet_profile_app/features/people/domain/entities/related_care.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_group.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_kind.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_role.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_status.dart';
import 'package:pet_profile_app/features/people/domain/enums/relationship_kind.dart';

ContactSummary _summary(String id) => ContactSummary(
  id: id,
  directory: const ContactDirectoryRef(type: 'personal'),
  kind: ContactKind.person,
  name: 'Name $id',
  roles: const [ContactRole.sitter],
  group: ContactGroup.carer,
  status: ContactStatus.active,
);

void main() {
  test('ContactUsage equality', () {
    const a = ContactUsage(
      kind: 'relationship',
      id: 'r1',
      label: 'Buddy',
      petId: 'p1',
      active: true,
    );
    const b = ContactUsage(
      kind: 'relationship',
      id: 'r1',
      label: 'Buddy',
      petId: 'p1',
      active: true,
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });

  test('Household and member equality', () {
    const member = HouseholdMember(
      userId: 'u1',
      displayName: 'You',
      firstName: 'You',
      tier: 'full_access',
      isOrganiser: true,
      isYou: true,
      ownsPetIds: ['p1'],
      sharesPetIds: const [],
    );
    final household = Household(
      id: 'h1',
      name: 'Home',
      myTier: 'full_access',
      myIsOrganiser: true,
      members: [member],
    );
    expect(household, household);
    expect(member, member);
    expect(household.hashCode, household.hashCode);
  });

  test('HouseholdInvite equality', () {
    const invite = HouseholdInvite(
      id: 'i1',
      source: 'household',
      email: 'a@b.com',
      householdId: 'h1',
      petIds: const ['p1'],
      createdAt: '2026-01-01',
    );
    expect(invite, invite);
    expect(invite.hashCode, invite.hashCode);
  });

  test('Person sealed variants equality', () {
    final summary = _summary('c1');
    final contact = ContactPerson(summary);
    expect(contact, ContactPerson(summary));
    expect(contact.id, 'c1');

    const member = HouseholdMember(
      userId: 'u1',
      displayName: 'A',
      firstName: 'A',
      tier: 'full_access',
      isOrganiser: false,
      isYou: false,
      ownsPetIds: const [],
      sharesPetIds: const [],
    );
    final household = Household(
      id: 'h1',
      name: 'H',
      myTier: 'full_access',
      myIsOrganiser: false,
      members: [member],
    );
    final memberPerson = HouseholdMemberPerson(
      household: household,
      member: member,
    );
    expect(
      memberPerson,
      HouseholdMemberPerson(household: household, member: member),
    );

    const invite = HouseholdInvite(
      id: 'i1',
      source: 'household',
      email: 'x@y.com',
      householdId: 'h1',
      petIds: const [],
    );
    final pending = PendingInvitePerson(invite);
    expect(pending, PendingInvitePerson(invite));
  });

  test('RelatedCare graph equality', () {
    const pet = RelatedCarePet(
      petId: 'p1',
      petName: 'Buddy',
      relationshipKind: RelationshipKind.primaryVet,
    );
    const item = RelatedCareItem(id: 'ci1', name: 'Walk', petId: 'p1');
    const absence = RelatedCareAbsence(
      absenceId: 'a1',
      startsOn: '2026-01-01',
      endsOn: '2026-01-05',
      petIds: const ['p1'],
    );
    const care = RelatedCare(
      pets: [pet],
      careItems: [item],
      absences: [absence],
      historyCount: 2,
    );
    expect(care, care);
    expect(pet, pet);
    expect(item, item);
    expect(absence, absence);
  });
}
