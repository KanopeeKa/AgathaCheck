import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/people/domain/entities/people_contact.dart';

void main() {
  test('PeopleContact value equality ignores object identity', () {
    const a = PeopleContact(
      id: 'c1',
      kind: 'person',
      name: 'Jamie',
      roles: ['sitter'],
      phone: '555',
    );
    const b = PeopleContact(
      id: 'c1',
      kind: 'person',
      name: 'Jamie',
      roles: ['sitter'],
      phone: '555',
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
  });
}
