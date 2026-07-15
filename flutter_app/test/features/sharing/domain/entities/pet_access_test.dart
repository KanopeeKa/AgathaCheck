import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/sharing/domain/entities/pet_access.dart';

void main() {
  group('PetAccessUser', () {
    test('displayName uses first and last name when present', () {
      const user = PetAccessUser(firstName: 'Jane', lastName: 'Doe');
      expect(user.displayName, 'Jane Doe');
    });

    test('displayName falls back to Unknown User when names empty', () {
      const user = PetAccessUser();
      expect(user.displayName, 'Unknown User');
    });

    test('initials use first letters of both names', () {
      const user = PetAccessUser(firstName: 'Jane', lastName: 'Doe');
      expect(user.initials, 'JD');
    });

    test('initials fall back for single-word display names', () {
      const user = PetAccessUser(firstName: 'Cher', lastName: '');
      expect(user.initials, 'CH');
    });
  });
}
