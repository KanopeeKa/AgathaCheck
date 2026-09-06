import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'package:pet_profile_app/features/pet_profile/data/datasources/pet_local_datasource.dart';
import 'package:pet_profile_app/features/pet_profile/data/datasources/pet_remote_datasource.dart';
import 'package:pet_profile_app/features/pet_profile/data/models/pet_model.dart';
import 'package:pet_profile_app/features/pet_profile/data/repositories/pet_repository_impl.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';

@GenerateNiceMocks([MockSpec<PetLocalDataSource>()])
import 'pet_repository_impl_test.mocks.dart';

/// Hand-written fake so we can assert exactly what hits the server.
class FakeRemoteDataSource implements PetRemoteDataSource {
  FakeRemoteDataSource({
    this.remotePets = const [],
    this.failCreate = false,
    this.failUpdate = false,
    this.failDelete = false,
  });

  List<PetModel> remotePets;
  bool failCreate;
  bool failUpdate;
  bool failDelete;
  final List<String> createdIds = [];

  @override
  Future<List<PetModel>> getAllPets(String token) async => remotePets;

  @override
  Future<List<PetModel>> getAllPetsIncludingOrg(String token) async =>
      remotePets;

  @override
  Future<PetModel> createPet(PetModel pet, String token) async {
    if (failCreate) {
      throw PetRemoteException('boom', statusCode: 500);
    }
    createdIds.add(pet.id);
    return pet;
  }

  @override
  Future<PetModel> updatePet(PetModel pet, String token) async {
    if (failUpdate) {
      throw PetRemoteException('boom', statusCode: 500);
    }
    return pet;
  }

  @override
  Future<void> deletePet(String id, String token) async {
    if (failDelete) {
      throw PetRemoteException('boom', statusCode: 500);
    }
  }

  @override
  Future<void> deletePetData(String id, String token) async {}

  @override
  Future<int> notifyPassedAway(
    String petId,
    String petName,
    String token,
  ) async => petName.contains('notify') ? 2 : 0;

  @override
  Future<PetModel> uploadPetPhoto(
    String petId,
    Uint8List bytes,
    String filename,
    String token,
  ) async {
    return PetModel(
      id: petId,
      name: 'Uploaded',
      species: 'Dog',
      photoPath: '/uploads/pet_photos/$filename',
    );
  }
}

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
      when(mockDataSource.getAllPets()).thenAnswer((_) async => [testModel]);

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
      when(
        mockDataSource.getPetById('test-id'),
      ).thenAnswer((_) async => testModel);

      final result = await repository.getPetById('test-id');

      expect(result, isNotNull);
      expect(result!.name, 'Buddy');
    });

    test('should return null when not found', () async {
      when(mockDataSource.getPetById('unknown')).thenAnswer((_) async => null);

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
      when(
        mockDataSource.deletePet('test-id'),
      ).thenAnswer((_) async => Future.value());

      await repository.deletePet('test-id');

      verify(mockDataSource.deletePet('test-id')).called(1);
    });
  });

  group('remote sync (server as source of truth)', () {
    late PetLocalDataSourceImpl local;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      local = PetLocalDataSourceImpl(prefs);
    });

    test(
      'getAllPets does NOT re-create local-only pets on the server and prunes '
      'them locally',
      () async {
        // A pet exists locally but the server no longer has it (e.g. deleted
        // directly in the DB). It must not resurrect.
        await local.addPet(testModel);
        final remote = FakeRemoteDataSource(remotePets: const []);
        final repo = PetRepositoryImpl(
          local,
          remoteDataSource: remote,
          token: 'tok',
        );

        final result = await repo.getAllPets();

        expect(result, isEmpty, reason: 'remote is authoritative');
        expect(
          remote.createdIds,
          isEmpty,
          reason: 'must never re-push the deleted pet',
        );
        expect(
          await local.getAllPets(),
          isEmpty,
          reason: 'stale local cache entry pruned',
        );
      },
    );

    test('getAllPets keeps pets that still exist on the server', () async {
      final remote = FakeRemoteDataSource(remotePets: [testModel]);
      final repo = PetRepositoryImpl(
        local,
        remoteDataSource: remote,
        token: 'tok',
      );

      final result = await repo.getAllPets();

      expect(result.length, 1);
      expect(result.first.id, 'test-id');
      expect(remote.createdIds, isEmpty);
    });

    test(
      'addPet rolls back local write and rethrows when the server fails',
      () async {
        final remote = FakeRemoteDataSource(failCreate: true);
        final repo = PetRepositoryImpl(
          local,
          remoteDataSource: remote,
          token: 'tok',
        );

        await expectLater(
          repo.addPet(testPet),
          throwsA(isA<PetRemoteException>()),
        );
        expect(
          await local.getAllPets(),
          isEmpty,
          reason: 'failed create must not linger in local cache',
        );
      },
    );

    test(
      'updatePet rolls back local write and rethrows when the server fails',
      () async {
        await local.addPet(testModel);
        final remote = FakeRemoteDataSource(failUpdate: true);
        final repo = PetRepositoryImpl(
          local,
          remoteDataSource: remote,
          token: 'tok',
        );
        final updatedPet = testPet.copyWith(name: 'Changed');

        await expectLater(
          repo.updatePet(updatedPet),
          throwsA(isA<PetRemoteException>()),
        );
        expect(
          (await local.getAllPets()).single.name,
          'Buddy',
          reason: 'failed update must restore the prior local snapshot',
        );
      },
    );

    test(
      'deletePet rolls back local write and rethrows when the server fails',
      () async {
        await local.addPet(testModel);
        final remote = FakeRemoteDataSource(failDelete: true);
        final repo = PetRepositoryImpl(
          local,
          remoteDataSource: remote,
          token: 'tok',
        );

        await expectLater(
          repo.deletePet('test-id'),
          throwsA(isA<PetRemoteException>()),
        );
        expect(
          (await local.getAllPets()).single.id,
          'test-id',
          reason: 'failed delete must restore the prior local snapshot',
        );
      },
    );

    test('addPet persists locally when the server accepts it', () async {
      final remote = FakeRemoteDataSource();
      final repo = PetRepositoryImpl(
        local,
        remoteDataSource: remote,
        token: 'tok',
      );

      final result = await repo.addPet(testPet);

      expect(result.id, 'test-id');
      expect(remote.createdIds, ['test-id']);
      expect((await local.getAllPets()).single.id, 'test-id');
    });

    test(
      'getAllPets preserves a local data: photo for a pet kept on the server',
      () async {
        const dataPhoto = 'data:image/png;base64,AAAA';
        await local.addPet(
          PetModel(
            id: 'test-id',
            name: 'Buddy',
            species: 'Dog',
            photoPath: dataPhoto,
          ),
        );
        // The server returns the same pet but without the inline photo.
        final remotePet = PetModel(
          id: 'test-id',
          name: 'Buddy',
          species: 'Dog',
        );
        final remote = FakeRemoteDataSource(remotePets: [remotePet]);
        final repo = PetRepositoryImpl(
          local,
          remoteDataSource: remote,
          token: 'tok',
        );

        final result = await repo.getAllPets();

        expect(
          result.single.photoPath,
          dataPhoto,
          reason: 'inline local photo must survive the remote merge',
        );
      },
    );
  });
}
