import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/data/models/pet_model.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';

void main() {
  final fullJson = {
    'id': 'test-id',
    'name': 'Buddy',
    'species': 'Dog',
    'breed': 'Golden Retriever',
    'dateOfBirth': '2022-01-15T00:00:00.000',
    'weight': 30.0,
    'gender': 'male',
    'bio': 'A friendly dog',
    'insurance': 'PetPlan Gold',
    'neuteredDate': '2023-03-10T00:00:00.000',
    'neuterDismissed': true,
    'chipId': 'CHIP-12345',
    'chipDismissed': false,
    'photoPath': '/photos/buddy.jpg',
    'vetId': 'vet-abc',
    'colorValue': 4286470082,
    'passedAway': false,
    'is_shared': true,
    'organization_id': 'org-99',
    'organization_name': 'Happy Paws',
  };

  final fullModel = PetModel(
    id: 'test-id',
    name: 'Buddy',
    species: 'Dog',
    breed: 'Golden Retriever',
    dateOfBirth: DateTime(2022, 1, 15),
    weight: 30.0,
    gender: 'male',
    bio: 'A friendly dog',
    insurance: 'PetPlan Gold',
    neuteredDate: DateTime(2023, 3, 10),
    neuterDismissed: true,
    chipId: 'CHIP-12345',
    chipDismissed: false,
    photoPath: '/photos/buddy.jpg',
    vetId: 'vet-abc',
    colorValue: 4286470082,
    passedAway: false,
    isShared: true,
    organizationId: 'org-99',
    organizationName: 'Happy Paws',
  );

  group('PetModel.fromJson', () {
    test('parses all fields correctly from camelCase JSON', () {
      final model = PetModel.fromJson(fullJson);

      expect(model.id, 'test-id');
      expect(model.name, 'Buddy');
      expect(model.species, 'Dog');
      expect(model.breed, 'Golden Retriever');
      expect(model.dateOfBirth, isNotNull);
      expect(model.dateOfBirth!.year, 2022);
      expect(model.dateOfBirth!.month, 1);
      expect(model.dateOfBirth!.day, 15);
      expect(model.weight, 30.0);
      expect(model.gender, 'male');
      expect(model.bio, 'A friendly dog');
      expect(model.insurance, 'PetPlan Gold');
      expect(model.neuteredDate, isNotNull);
      expect(model.neuteredDate!.year, 2023);
      expect(model.neuteredDate!.month, 3);
      expect(model.neuteredDate!.day, 10);
      expect(model.neuterDismissed, isTrue);
      expect(model.chipId, 'CHIP-12345');
      expect(model.chipDismissed, isFalse);
      expect(model.photoPath, '/photos/buddy.jpg');
      expect(model.vetId, 'vet-abc');
      expect(model.colorValue, 4286470082);
      expect(model.passedAway, isFalse);
      expect(model.isShared, isTrue);
      expect(model.organizationId, 'org-99');
      expect(model.organizationName, 'Happy Paws');
    });

    test('parses snake_case date_of_birth', () {
      final json = {
        'id': 'test-id',
        'name': 'Buddy',
        'species': 'Dog',
        'date_of_birth': '2022-01-15',
      };
      final model = PetModel.fromJson(json);
      expect(model.dateOfBirth, isNotNull);
      expect(model.dateOfBirth!.year, 2022);
    });

    test('handles null optional fields with defaults', () {
      final json = {
        'id': 'min-id',
        'name': 'Min',
        'species': 'Cat',
      };
      final model = PetModel.fromJson(json);

      expect(model.breed, '');
      expect(model.dateOfBirth, isNull);
      expect(model.weight, isNull);
      expect(model.gender, isNull);
      expect(model.bio, '');
      expect(model.insurance, '');
      expect(model.neuteredDate, isNull);
      expect(model.neuterDismissed, isFalse);
      expect(model.chipId, '');
      expect(model.chipDismissed, isFalse);
      expect(model.photoPath, isNull);
      expect(model.vetId, isNull);
      expect(model.colorValue, isNull);
      expect(model.passedAway, isFalse);
      expect(model.isShared, isFalse);
      expect(model.organizationId, isNull);
      expect(model.organizationName, isNull);
    });

    test('passedAway true is parsed correctly', () {
      final json = {
        'id': 'p1',
        'name': 'Max',
        'species': 'Dog',
        'passedAway': true,
      };
      final model = PetModel.fromJson(json);
      expect(model.passedAway, isTrue);
    });

    test('parses legacy UTC timestamp for date of birth', () {
      final json = {
        'id': 'p1',
        'name': 'Buddy',
        'species': 'Dog',
        'dateOfBirth': '2022-01-15T00:00:00.000Z',
      };
      final model = PetModel.fromJson(json);
      expect(model.dateOfBirth!.day, 15);
    });

    test('organization_id as int is coerced to string', () {
      final json = {
        'id': 'p1',
        'name': 'Max',
        'species': 'Dog',
        'organization_id': 42,
      };
      final model = PetModel.fromJson(json);
      expect(model.organizationId, '42');
    });
  });

  group('PetModel.toJson', () {
    test('serializes calendar dates as date-only', () {
      final json = fullModel.toJson();
      expect(json['dateOfBirth'], '2022-01-15');
      expect(json['neuteredDate'], '2023-03-10');
      expect(json['dateOfBirth'], isNot(contains('T')));
    });

    test('produces correct output with all fields', () {
      final json = fullModel.toJson();

      expect(json['id'], 'test-id');
      expect(json['name'], 'Buddy');
      expect(json['species'], 'Dog');
      expect(json['breed'], 'Golden Retriever');
      expect(json['dateOfBirth'], isNotNull);
      expect(json['weight'], 30.0);
      expect(json['gender'], 'male');
      expect(json['bio'], 'A friendly dog');
      expect(json['insurance'], 'PetPlan Gold');
      expect(json['neuteredDate'], isNotNull);
      expect(json['neuterDismissed'], isTrue);
      expect(json['chipId'], 'CHIP-12345');
      expect(json['chipDismissed'], isFalse);
      expect(json['photoPath'], '/photos/buddy.jpg');
      expect(json['vetId'], 'vet-abc');
      expect(json['colorValue'], 4286470082);
      expect(json['passedAway'], isFalse);
      expect(json['organization_id'], 'org-99');
      expect(json['organization_name'], 'Happy Paws');
    });

    test('null optional fields produce null in JSON', () {
      const model = PetModel(id: 'x', name: 'X', species: 'Cat');
      final json = model.toJson();

      expect(json['dateOfBirth'], isNull);
      expect(json['weight'], isNull);
      expect(json['gender'], isNull);
      expect(json['neuteredDate'], isNull);
      expect(json['photoPath'], isNull);
      expect(json['vetId'], isNull);
      expect(json['colorValue'], isNull);
      expect(json['organization_id'], isNull);
      expect(json['organization_name'], isNull);
    });
  });

  group('PetModel.toEntity', () {
    test('converts all fields to Pet entity', () {
      final entity = fullModel.toEntity();

      expect(entity, isA<Pet>());
      expect(entity.id, 'test-id');
      expect(entity.name, 'Buddy');
      expect(entity.species, 'Dog');
      expect(entity.breed, 'Golden Retriever');
      expect(entity.dateOfBirth, isNotNull);
      expect(entity.weight, 30.0);
      expect(entity.gender, 'male');
      expect(entity.bio, 'A friendly dog');
      expect(entity.insurance, 'PetPlan Gold');
      expect(entity.neuteredDate, isNotNull);
      expect(entity.neuterDismissed, isTrue);
      expect(entity.chipId, 'CHIP-12345');
      expect(entity.chipDismissed, isFalse);
      expect(entity.photoPath, '/photos/buddy.jpg');
      expect(entity.vetId, 'vet-abc');
      expect(entity.colorValue, 4286470082);
      expect(entity.passedAway, isFalse);
      expect(entity.isShared, isTrue);
      expect(entity.organizationId, 'org-99');
      expect(entity.organizationName, 'Happy Paws');
    });
  });

  group('PetModel.fromEntity', () {
    test('preserves all fields from Pet entity', () {
      final pet = Pet(
        id: 'test-id',
        name: 'Buddy',
        species: 'Dog',
        breed: 'Golden Retriever',
        dateOfBirth: DateTime(2022, 1, 15),
        weight: 30.0,
        gender: 'male',
        bio: 'A friendly dog',
        insurance: 'PetPlan Gold',
        neuteredDate: DateTime(2023, 3, 10),
        neuterDismissed: true,
        chipId: 'CHIP-12345',
        chipDismissed: false,
        photoPath: '/photos/buddy.jpg',
        vetId: 'vet-abc',
        colorValue: 4286470082,
        passedAway: true,
        isShared: true,
        organizationId: 'org-99',
        organizationName: 'Happy Paws',
      );
      final model = PetModel.fromEntity(pet);

      expect(model.id, pet.id);
      expect(model.name, pet.name);
      expect(model.species, pet.species);
      expect(model.breed, pet.breed);
      expect(model.dateOfBirth, pet.dateOfBirth);
      expect(model.weight, pet.weight);
      expect(model.gender, pet.gender);
      expect(model.bio, pet.bio);
      expect(model.insurance, pet.insurance);
      expect(model.neuteredDate, pet.neuteredDate);
      expect(model.neuterDismissed, pet.neuterDismissed);
      expect(model.chipId, pet.chipId);
      expect(model.chipDismissed, pet.chipDismissed);
      expect(model.photoPath, pet.photoPath);
      expect(model.vetId, pet.vetId);
      expect(model.colorValue, pet.colorValue);
      expect(model.passedAway, pet.passedAway);
      expect(model.isShared, pet.isShared);
      expect(model.organizationId, pet.organizationId);
      expect(model.organizationName, pet.organizationName);
    });
  });

  group('PetModel JSON round-trip', () {
    test('round-trips through toJson and fromJson', () {
      final json = fullModel.toJson();
      final restored = PetModel.fromJson(json);

      expect(restored.id, fullModel.id);
      expect(restored.name, fullModel.name);
      expect(restored.species, fullModel.species);
      expect(restored.breed, fullModel.breed);
      expect(restored.weight, fullModel.weight);
      expect(restored.gender, fullModel.gender);
      expect(restored.bio, fullModel.bio);
      expect(restored.insurance, fullModel.insurance);
      expect(restored.neuterDismissed, fullModel.neuterDismissed);
      expect(restored.chipId, fullModel.chipId);
      expect(restored.chipDismissed, fullModel.chipDismissed);
      expect(restored.photoPath, fullModel.photoPath);
      expect(restored.vetId, fullModel.vetId);
      expect(restored.colorValue, fullModel.colorValue);
      expect(restored.passedAway, fullModel.passedAway);
    });

    test('round-trips through toJsonString and fromJsonString', () {
      final jsonStr = fullModel.toJsonString();
      final restored = PetModel.fromJsonString(jsonStr);

      expect(restored.id, fullModel.id);
      expect(restored.name, fullModel.name);
      expect(restored.colorValue, fullModel.colorValue);
      expect(restored.passedAway, fullModel.passedAway);
    });
  });
}
