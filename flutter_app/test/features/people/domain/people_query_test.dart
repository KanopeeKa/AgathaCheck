import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/people/domain/entities/contact_summary.dart';
import 'package:pet_profile_app/features/people/domain/entities/roster.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_group.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_kind.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_role.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_status.dart';
import 'package:pet_profile_app/features/people/domain/enums/relationship_kind.dart';
import 'package:pet_profile_app/features/people/domain/services/people_query.dart';

ContactSummary _contact({
  required String id,
  ContactStatus status = ContactStatus.active,
  ContactGroup group = ContactGroup.carer,
  List<ContactPetLink> pets = const [],
}) {
  return ContactSummary(
    id: id,
    directory: const ContactDirectoryRef(type: 'personal'),
    kind: ContactKind.person,
    name: 'Person $id',
    roles: const [ContactRole.sitter],
    group: group,
    status: status,
    pets: pets,
  );
}

void main() {
  test('inactive contacts excluded unless currentId pinned', () {
    final roster = Roster(
      households: const [],
      contacts: [
        _contact(id: 'active'),
        _contact(id: 'old', status: ContactStatus.inactive),
      ],
      pendingInvites: const [],
    );

    final withoutCurrent = buildPeoplePickerData(roster, const PeopleQuery());
    final allOptions = withoutCurrent.sections
        .expand((s) => s.options)
        .map((o) => o.optionId)
        .toList();
    expect(allOptions, ['active']);
    expect(withoutCurrent.pinned, isNull);

    final withCurrent = buildPeoplePickerData(
      roster,
      const PeopleQuery(currentId: 'old'),
    );
    expect(withCurrent.pinned, isA<ContactPickerOption>());
    expect((withCurrent.pinned! as ContactPickerOption).contact.id, 'old');
    expect(allOptions, ['active']);
  });

  test('pet scope limits options', () {
    final roster = Roster(
      households: const [],
      contacts: [
        _contact(
          id: 'a',
          pets: const [
            ContactPetLink(
              petId: 'p1',
              petName: 'Buddy',
              relationshipKind: RelationshipKind.careProvider,
            ),
          ],
        ),
        _contact(id: 'b'),
      ],
      pendingInvites: const [],
    );

    final data = buildPeoplePickerData(roster, const PeopleQuery(petId: 'p1'));
    final ids = data.sections
        .expand((s) => s.options)
        .map((o) => o.optionId)
        .toList();
    expect(ids, ['a']);
  });
}
