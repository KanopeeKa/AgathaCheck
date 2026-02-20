import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';

void main() {
  group('Pet', () {
    const pet = Pet(
      id: 'test-id',
      name: 'Buddy',
      species: 'Dog',
      breed: 'Golden Retriever',
      age: 3.0,
      weight: 30.0,
      bio: 'A friendly dog',
    );

    test('should create with required fields', () {
      const minimal = Pet(id: '1', name: 'Rex', species: 'Dog');
      expect(minimal.id, '1');
      expect(minimal.name, 'Rex');
      expect(minimal.species, 'Dog');
      expect(minimal.breed, '');
      expect(minimal.age, isNull);
      expect(minimal.weight, isNull);
      expect(minimal.bio, '');
      expect(minimal.photoPath, isNull);
    });

    test('copyWith should create a new instance with updated fields', () {
      final updated = pet.copyWith(name: 'Max', age: 5.0);

      expect(updated.name, 'Max');
      expect(updated.age, 5.0);
      expect(updated.id, pet.id);
      expect(updated.species, pet.species);
      expect(updated.breed, pet.breed);
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
