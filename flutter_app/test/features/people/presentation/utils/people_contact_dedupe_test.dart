import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/people/domain/entities/people_contact.dart';
import 'package:pet_profile_app/features/people/presentation/utils/people_contact_dedupe.dart';

void main() {
  test('findDuplicateContacts matches phone digits', () {
    const a = PeopleContact(
      id: '1',
      kind: 'person',
      name: 'Jamie Taylor',
      roles: ['sitter'],
      phone: '01234 567890',
    );
    final matches = findDuplicateContacts(
      directory: [a],
      name: 'Jam',
      phone: '01234567890',
    );
    expect(matches, hasLength(1));
  });
}
