import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
  final List<String> dataCleanups = [];
  final List<Pet> passedAway = [];

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

  @override
  Future<void> deletePetWithDataCleanup(String id) async {
    dataCleanups.add(id);
    deleted.add(id);
  }

  @override
  Future<bool> markPassedAway(Pet pet) async {
    passedAway.add(pet);
    updated.add(pet.copyWith(passedAway: true, colorValue: 0xFFFFFFFF));
    return pet.name.contains('notify');
  }
}

ProviderContainer makeContainer({
  required RecordingPetRepository repo,
}) {
  final container = ProviderContainer(
    overrides: [
      authProvider.overrideWith((ref) => FakeAuthNotifier()),
      petRepositoryProvider.overrideWithValue(repo),
      allPetsIncludingOrgProvider.overrideWith((ref) async => <Pet>[]),
    ],
  );
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
      final id = await container
          .read(petListProvider.notifier)
          .addPet(name: 'Buddy', species: 'cat', organizationId: 'org-9');

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
    test('delegates cascade delete to the repository', () async {
      final repo = RecordingPetRepository(initial: [samplePet()]);
      final container = makeContainer(repo: repo);
      addTearDown(container.dispose);

      await container.read(petListProvider.future);
      await container.read(petListProvider.notifier).deletePet('pet-1');

      expect(repo.dataCleanups, ['pet-1']);
      expect(repo.deleted, ['pet-1']);
    });
  });

  group('PetListNotifier.markPassedAway', () {
    test('delegates to repository and returns notify result', () async {
      final repo = RecordingPetRepository(
        initial: [samplePet().copyWith(name: 'notify Rex')],
      );
      final container = makeContainer(repo: repo);
      addTearDown(container.dispose);

      await container.read(petListProvider.future);
      final hasSharedUsers = await container
          .read(petListProvider.notifier)
          .markPassedAway('pet-1');

      expect(repo.passedAway, hasLength(1));
      expect(repo.passedAway.single.name, 'notify Rex');
      expect(repo.updated.single.passedAway, true);
      expect(hasSharedUsers, true);
    });

    test('returns false when pet is unknown', () async {
        final repo = RecordingPetRepository(initial: [samplePet()]);
        final container = makeContainer(repo: repo);
        addTearDown(container.dispose);

        await container.read(petListProvider.future);
        final result = await container
            .read(petListProvider.notifier)
            .markPassedAway('does-not-exist');

        expect(result, false);
        expect(repo.updated, isEmpty);
      },
    );
  });
}
