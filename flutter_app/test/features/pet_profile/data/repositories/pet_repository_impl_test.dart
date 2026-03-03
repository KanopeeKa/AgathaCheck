import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pet_profile_app/features/pet_profile/data/datasources/pet_local_datasource.dart';
import 'package:pet_profile_app/features/pet_profile/data/models/pet_model.dart';
import 'package:pet_profile_app/features/pet_profile/data/repositories/pet_repository_impl.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';

@GenerateNiceMocks([MockSpec<PetLocalDataSource>()])
import 'pet_repository_impl_test.mocks.dart';

void main() {
  late MockPetLocalDataSource mockDataSource;
  late PetRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockPetLocalDataSource();
    repository = PetRepositoryImpl(mockDataSource);
  });

  final testModel = PetModel(
    id: 'test-id',
    name: 'Buddy',
    species: 'Dog',
    breed: 'Golden Retriever',
    dateOfBirth: DateTime(2022, 1, 15),
    weight: 30.0,
    bio: 'A friendly dog',
  );

  final testPet = Pet(
    id: 'test-id',
    name: 'Buddy',
    species: 'Dog',
    breed: 'Golden Retriever',
    dateOfBirth: DateTime(2022, 1, 15),
    weight: 30.0,
    bio: 'A friendly dog',
  );

  group('getAllPets', () {
    test('should return list of pets from data source', () async {
      when(mockDataSource.getAllPets())
          .thenAnswer((_) async => [testModel]);

      final result = await repository.getAllPets();

      expect(result.length, 1);
      expect(result.first.name, 'Buddy');
      verify(mockDataSource.getAllPets()).called(1);
    });

    test('should return empty list when no pets stored', () async {
      when(mockDataSource.getAllPets()).thenAnswer((_) async => []);

      final result = await repository.getAllPets();

      expect(result, isEmpty);
    });
  });

  group('getPetById', () {
    test('should return pet when found', () async {
      when(mockDataSource.getPetById('test-id'))
          .thenAnswer((_) async => testModel);

      final result = await repository.getPetById('test-id');

      expect(result, isNotNull);
      expect(result!.name, 'Buddy');
    });

    test('should return null when not found', () async {
      when(mockDataSource.getPetById('unknown'))
          .thenAnswer((_) async => null);

      final result = await repository.getPetById('unknown');

      expect(result, isNull);
    });
  });

  group('addPet', () {
    test('should add pet and return entity', () async {
      when(mockDataSource.addPet(any)).thenAnswer((_) async => testModel);

      final result = await repository.addPet(testPet);

      expect(result.name, 'Buddy');
      verify(mockDataSource.addPet(any)).called(1);
    });
  });

  group('updatePet', () {
    test('should update pet and return entity', () async {
      when(mockDataSource.updatePet(any)).thenAnswer((_) async => testModel);

      final result = await repository.updatePet(testPet);

      expect(result.name, 'Buddy');
      verify(mockDataSource.updatePet(any)).called(1);
    });
  });

  group('deletePet', () {
    test('should delete pet from data source', () async {
      when(mockDataSource.deletePet('test-id'))
          .thenAnswer((_) async => Future.value());

      await repository.deletePet('test-id');

      verify(mockDataSource.deletePet('test-id')).called(1);
    });
  });
}
