import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/people/domain/entities/pet_people.dart';
import 'package:pet_profile_app/features/people/domain/enums/relationship_kind.dart';
import 'package:pet_profile_app/features/people/domain/services/contact_vet_mapping.dart';
import 'package:pet_profile_app/features/people/domain/entities/contact_detail.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_group.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_kind.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_role.dart';
import 'package:pet_profile_app/features/people/domain/enums/contact_status.dart';
import 'package:pet_profile_app/features/people/domain/entities/contact_summary.dart';
import 'package:pet_profile_app/features/people/domain/services/pet_people_slots.dart';

void main() {
  test('vetFromContactDetail includes contact coordinates (B7)', () {
    final detail = ContactDetail(
      id: 'c1',
      directoryId: 'd1',
      directory: const ContactDirectoryRef(type: 'personal'),
      kind: ContactKind.organisation,
      name: 'Greenhill Vet',
      roles: const [ContactRole.vet],
      group: ContactGroup.professional,
      status: ContactStatus.active,
      phone: '555-0100',
      email: 'desk@greenhill.example',
      address: '1 High Street',
      website: 'https://greenhill.example',
      legacyVetId: 'vet-1',
    );
    final vet = vetFromContactDetail(detail);
    expect(vet, isNotNull);
    expect(vet!.phone, '555-0100');
    expect(vet.email, 'desk@greenhill.example');
    expect(vet.address, '1 High Street');
    expect(vet.website, 'https://greenhill.example');
  });

  test('primaryVetRelationship returns active primary vet row', () {
    const people = PetPeople(
      petId: 'p1',
      petName: 'Buddy',
      scope: 'owner',
      owner: PetPeopleOwner(userId: 'u1', displayName: 'Alex'),
      householdMembers: const [],
      relationships: [
        PetRelationship(
          id: 'r1',
          petId: 'p1',
          contactId: 'vet-contact',
          relationshipKind: RelationshipKind.primaryVet,
          isPrimary: true,
          active: true,
          contactKind: 'organisation',
          contactName: 'Greenhill',
          contactPhone: '555',
        ),
      ],
    );
    expect(primaryVetRelationship(people)?.contactId, 'vet-contact');
  });
}
