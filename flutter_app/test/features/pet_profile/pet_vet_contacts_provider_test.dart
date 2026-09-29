import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/people/domain/entities/people_contact.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_vet_contacts_provider.dart';

void main() {
  test('petVetOptionsFromContacts maps legacy vet id and name', () {
    const contacts = [
      PeopleContact(
        id: 'c1',
        kind: 'organisation',
        name: 'Happy Paws',
        roles: ['vet'],
        legacyVetId: 'vet-1',
      ),
      PeopleContact(
        id: 'c2',
        kind: 'person',
        name: 'Walker',
        roles: ['walker'],
        legacyVetId: null,
      ),
    ];

    final options = petVetOptionsFromContacts(contacts);
    expect(options.length, 1);
    expect(options.first.vetId, 'vet-1');
    expect(options.first.displayName, 'Happy Paws');
  });
}
