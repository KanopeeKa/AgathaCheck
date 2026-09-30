import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/people/domain/entities/people_contact.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_vet_contacts_provider.dart';

void main() {
  test('petVetOptionsFromContacts includes contact coordinates (B7)', () {
    const contacts = [
      PeopleContact(
        id: 'c1',
        kind: 'organisation',
        name: 'Greenhill Vet',
        roles: ['vet'],
        phone: '555-0100',
        email: 'desk@greenhill.example',
        address: '1 High Street',
        website: 'https://greenhill.example',
        legacyVetId: 'vet-1',
      ),
    ];
    final options = petVetOptionsFromContacts(contacts);
    expect(options, hasLength(1));
    expect(options.first.phone, '555-0100');
    expect(options.first.email, 'desk@greenhill.example');
    expect(options.first.address, '1 High Street');
    expect(options.first.website, 'https://greenhill.example');
  });
}
