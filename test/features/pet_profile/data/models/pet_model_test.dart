import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/data/models/pet_model.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';

void main() {
  final testModel = PetModel(
    id: 'test-id',
    name: 'Buddy',
    species: 'Dog',
    breed: 'Golden Retriever',
    dateOfBirth: DateTime(2022, 1, 15),
    weight: 30.0,
    bio: 'A friendly dog',
  );

  final testJson = {
    'id': 'test-id',
    'name': 'Buddy',
    'species': 'Dog',
    'breed': 'Golden Retriever',
    'dateOfBirth': '2022-01-15T00:00:00.000',
    'weight': 30.0,
    'bio': 'A friendly dog',
    'photoPath': null,
  };

  group('PetModel', () {
    test('should create from JSON with camelCase dateOfBirth', () {
      final model = PetModel.fromJson(testJson);

      expect(model.id, 'test-id');
      expect(model.name, 'Buddy');
      expect(model.species, 'Dog');
      expect(model.breed, 'Golden Retriever');
      expect(model.dateOfBirth, isNotNull);
      expect(model.dateOfBirth!.year, 2022);
      expect(model.dateOfBirth!.month, 1);
      expect(model.dateOfBirth!.day, 15);
      expect(model.weight, 30.0);
      expect(model.bio, 'A friendly dog');
    });

    test('should create from JSON with snake_case date_of_birth', () {
      final snakeJson = {
        'id': 'test-id',
        'name': 'Buddy',
        'species': 'Dog',
        'date_of_birth': '2022-01-15',
      };
      final model = PetModel.fromJson(snakeJson);

      expect(model.dateOfBirth, isNotNull);
      expect(model.dateOfBirth!.year, 2022);
    });

    test('should convert to JSON', () {
      final json = testModel.toJson();

      expect(json['id'], 'test-id');
      expect(json['name'], 'Buddy');
      expect(json['species'], 'Dog');
      expect(json['dateOfBirth'], isNotNull);
    });

    test('should convert to entity', () {
      final entity = testModel.toEntity();

      expect(entity, isA<Pet>());
      expect(entity.id, 'test-id');
      expect(entity.name, 'Buddy');
      expect(entity.dateOfBirth, isNotNull);
    });

    test('should create from entity', () {
      final pet = Pet(
        id: 'test-id',
        name: 'Buddy',
        species: 'Dog',
        breed: 'Golden Retriever',
        dateOfBirth: DateTime(2022, 1, 15),
      );
      final model = PetModel.fromEntity(pet);

      expect(model.id, pet.id);
      expect(model.name, pet.name);
      expect(model.species, pet.species);
      expect(model.dateOfBirth, pet.dateOfBirth);
    });

    test('should round-trip JSON string', () {
      final jsonStr = testModel.toJsonString();
      final restored = PetModel.fromJsonString(jsonStr);

      expect(restored.id, testModel.id);
      expect(restored.name, testModel.name);
    });

    test('should handle null optional fields in JSON', () {
      final minimalJson = {
        'id': 'min-id',
        'name': 'Min',
        'species': 'Cat',
      };
      final model = PetModel.fromJson(minimalJson);

      expect(model.breed, '');
      expect(model.dateOfBirth, isNull);
      expect(model.weight, isNull);
      expect(model.bio, '');
      expect(model.photoPath, isNull);
    });
  });
}
