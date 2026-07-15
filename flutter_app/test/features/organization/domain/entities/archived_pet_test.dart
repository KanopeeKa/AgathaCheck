import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/organization/domain/entities/archived_pet.dart';

void main() {
  group('ArchivedPet', () {
    test('hasShadowSnapshot is true when map is non-empty', () {
      const pet = ArchivedPet(
        id: 'a1',
        petId: 'p1',
        petName: 'Fluffy',
        shadowSnapshot: {'name': 'Fluffy'},
      );
      expect(pet.hasShadowSnapshot, isTrue);
    });

    test('hasShadowSnapshot is false when map is null or empty', () {
      const empty = ArchivedPet(
        id: 'a1',
        petId: 'p1',
        petName: 'Fluffy',
        shadowSnapshot: {},
      );
      const none = ArchivedPet(id: 'a1', petId: 'p1', petName: 'Fluffy');
      expect(empty.hasShadowSnapshot, isFalse);
      expect(none.hasShadowSnapshot, isFalse);
    });

    test('equality is based on id', () {
      const a = ArchivedPet(id: 'same', petId: 'p1', petName: 'A');
      const b = ArchivedPet(id: 'same', petId: 'p2', petName: 'B');
      const c = ArchivedPet(id: 'other', petId: 'p1', petName: 'A');
      expect(a, equals(b));
      expect(a == c, isFalse);
    });
  });
}
