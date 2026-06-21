import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pet_profile_app/core/providers/api_base_url_provider.dart';
import 'package:pet_profile_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/repositories/pet_repository.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/providers/pet_providers.dart';

import '../../../../helpers/fakes.dart';

/// Records every repository call so we can assert what the notifier delegated.
class RecordingPetRepository implements PetRepository {
  RecordingPetRepository({this.initial = const []});

  final List<Pet> initial;
  final List<Pet> added = [];
  final List<Pet> updated = [];
  final List<String> deleted = [];

  @override
  Future<List<Pet>> getAllPets() async => initial;
  @override
  Future<Pet?> getPetById(String id) async {
    for (final p in initial) {
      if (p.id == id) return p;
    }
    return null;
  }
  @override
  Future<Pet> addPet(Pet pet) async {
    added.add(pet);
    return pet;
  }

  @override
  Future<Pet> updatePet(Pet pet) async {
    updated.add(pet);
    return pet;
  }

  @override
  Future<void> deletePet(String id) async {
    deleted.add(id);
  }
}

ProviderContainer makeContainer({
  required RecordingPetRepository repo,
  http.Client? client,
  List<http.BaseRequest> capturedRequests = const [],
}) {
  final mockClient = client ??
      MockClient((request) async {
        return http.Response('{"notified_count":0}', 200);
      });
  final container = ProviderContainer(overrides: [
    authProvider.overrideWith((ref) => FakeAuthNotifier()),
    petRepositoryProvider.overrideWithValue(repo),
    apiBaseUrlProvider.overrideWithValue('http://test.local'),
    authHttpClientProvider.overrideWithValue(mockClient),
    allPetsIncludingOrgProvider.overrideWith((ref) async => <Pet>[]),
  ]);
  return container;
}

Pet samplePet({String id = 'pet-1', bool passedAway = false}) => Pet(
      id: id,
      name: 'Rex',
      species: 'dog',
      colorValue: 0xFF7E57C2,
      passedAway: passedAway,
    );

void main() {
  group('PetListNotifier.addPet', () {
    test('delegates to the repository with the supplied fields', () async {
      final repo = RecordingPetRepository();
      final container = makeContainer(repo: repo);
      addTearDown(container.dispose);

      await container.read(petListProvider.future);
      final id = await container.read(petListProvider.notifier).addPet(
            name: 'Buddy',
            species: 'cat',
            organizationId: 'org-9',
          );

      expect(repo.added, hasLength(1));
      expect(repo.added.single.name, 'Buddy');
      expect(repo.added.single.species, 'cat');
      expect(repo.added.single.organizationId, 'org-9');
      expect(repo.added.single.id, id);
    });
  });

  group('PetListNotifier.updatePet', () {
    test('delegates the updated pet to the repository', () async {
      final repo = RecordingPetRepository(initial: [samplePet()]);
      final container = makeContainer(repo: repo);
      addTearDown(container.dispose);

      await container.read(petListProvider.future);
      final edited = samplePet().copyWith(name: 'Rex Updated');
      await container.read(petListProvider.notifier).updatePet(edited);

      expect(repo.updated, hasLength(1));
      expect(repo.updated.single.name, 'Rex Updated');
    });
  });

  group('PetListNotifier.deletePet', () {
    test('deletes via the repository and calls the data endpoint', () async {
      final repo = RecordingPetRepository(initial: [samplePet()]);
      final requests = <http.BaseRequest>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('{}', 200);
      });
      final container = makeContainer(repo: repo, client: client);
      addTearDown(container.dispose);

      await container.read(petListProvider.future);
      await container.read(petListProvider.notifier).deletePet('pet-1');

      expect(repo.deleted, ['pet-1']);
      expect(requests.single.method, 'DELETE');
      expect(requests.single.url.path, '/api/pets/pet-1/data');
    });
  });

  group('PetListNotifier.markPassedAway', () {
    test('persists passedAway and notifies the backend', () async {
      final repo = RecordingPetRepository(initial: [samplePet()]);
      final requests = <http.BaseRequest>[];
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response('{"notified_count":2}', 200);
      });
      final container = makeContainer(repo: repo, client: client);
      addTearDown(container.dispose);

      await container.read(petListProvider.future);
      final hasSharedUsers =
          await container.read(petListProvider.notifier).markPassedAway('pet-1');

      expect(repo.updated, hasLength(1));
      expect(repo.updated.single.passedAway, true);
      expect(repo.updated.single.colorValue, 0xFFFFFFFF);
      expect(requests.single.method, 'POST');
      expect(requests.single.url.path, '/api/pets/pet-1/passed-away');
      expect(hasSharedUsers, true);
    });

    test('returns false and persists nothing when the pet is unknown', () async {
      final repo = RecordingPetRepository(initial: [samplePet()]);
      final container = makeContainer(repo: repo);
      addTearDown(container.dispose);

      await container.read(petListProvider.future);
      final result = await container
          .read(petListProvider.notifier)
          .markPassedAway('does-not-exist');

      expect(result, false);
      expect(repo.updated, isEmpty);
    });
  });
}
