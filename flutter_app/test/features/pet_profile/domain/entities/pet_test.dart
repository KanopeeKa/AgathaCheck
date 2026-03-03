import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';

void main() {
  group('Pet', () {
    final pet = Pet(
      id: 'test-id',
      name: 'Buddy',
      species: 'Dog',
      breed: 'Golden Retriever',
      dateOfBirth: DateTime(2022, 1, 15),
      weight: 30.0,
      bio: 'A friendly dog',
    );

    test('should create with required fields', () {
      const minimal = Pet(id: '1', name: 'Rex', species: 'Dog');
      expect(minimal.id, '1');
      expect(minimal.name, 'Rex');
      expect(minimal.species, 'Dog');
      expect(minimal.breed, '');
      expect(minimal.dateOfBirth, isNull);
      expect(minimal.age, isNull);
      expect(minimal.weight, isNull);
      expect(minimal.bio, '');
      expect(minimal.photoPath, isNull);
    });

    test('copyWith should create a new instance with updated fields', () {
      final newDob = DateTime(2020, 6, 1);
      final updated = pet.copyWith(name: 'Max', dateOfBirth: newDob);

      expect(updated.name, 'Max');
      expect(updated.dateOfBirth, newDob);
      expect(updated.id, pet.id);
      expect(updated.species, pet.species);
      expect(updated.breed, pet.breed);
    });

    test('age should be computed from dateOfBirth', () {
      expect(pet.dateOfBirth, isNotNull);
      expect(pet.age, isNotNull);
      expect(pet.age!, greaterThan(0));
    });

    test('ageDisplay should return human-readable age', () {
      expect(pet.ageDisplay, isNotNull);
      expect(pet.ageDisplay!, contains('yrs'));
    });

    test('ageDisplay should show months for young pets', () {
      final youngPet = Pet(
        id: 'young',
        name: 'Puppy',
        species: 'Dog',
        dateOfBirth: DateTime.now().subtract(const Duration(days: 90)),
      );
      expect(youngPet.ageDisplay, isNotNull);
      expect(youngPet.ageDisplay!, contains('month'));
    });

    test('equality is based on id', () {
      const same = Pet(id: 'test-id', name: 'Different', species: 'Cat');
      const different = Pet(id: 'other-id', name: 'Buddy', species: 'Dog');

      expect(pet == same, isTrue);
      expect(pet == different, isFalse);
    });

    test('hashCode is based on id', () {
      const same = Pet(id: 'test-id', name: 'Different', species: 'Cat');
      expect(pet.hashCode, equals(same.hashCode));
    });
  });
}
