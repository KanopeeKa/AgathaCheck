import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/controllers/pet_form_controller.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/controllers/pet_form_outcomes.dart';

import '../providers/pet_list_notifier_test.dart';

void main() {
  group('PetFormController.populateForm', () {
    test('maps every Pet field into the form state', () {
      final controller = PetFormController();
      final pet = Pet(
        id: 'pet-1',
        name: 'Rex',
        species: 'dog',
        breed: 'Labrador',
        weight: 12.5,
        bio: 'A good boy',
        insurance: 'PetPlan #9',
        chipId: 'CHIP-77',
        gender: 'male',
        photoPath: 'base64data',
        vetId: 'vet-1',
        colorValue: 0xFF7E57C2,
        dateOfBirth: DateTime(2020, 1, 1),
        neuteredDate: DateTime(2021, 6, 1),
        neuterDismissed: true,
        chipDismissed: true,
        passedAway: true,
        organizationId: 'org-1',
      );

      controller.populateForm(pet);
      final state = controller.state;

      expect(state.name, 'Rex');
      expect(state.breed, 'Labrador');
      expect(state.weight, '12.5');
      expect(state.bio, 'A good boy');
      expect(state.insurance, 'PetPlan #9');
      expect(state.chipId, 'CHIP-77');
      expect(state.selectedSpecies, 'dog');
      expect(state.selectedGender, 'male');
      expect(state.photoBase64, 'base64data');
      expect(state.selectedVetId, 'vet-1');
      expect(state.existingColorValue, 0xFF7E57C2);
      expect(state.dateOfBirth, DateTime(2020, 1, 1));
      expect(state.neuteredDate, DateTime(2021, 6, 1));
      expect(state.isNeutered, true);
      expect(state.neuterDismissed, true);
      expect(state.chipDismissed, true);
      expect(state.passedAway, true);
      expect(state.selectedOrgId, 'org-1');
    });

    test('represents a null weight as an empty string', () {
      final controller = PetFormController();
      controller.populateForm(const Pet(id: 'p', name: 'Spot', species: 'cat'));
      expect(controller.state.weight, '');
    });

    test('leaves isNeutered null when there is no neutered date', () {
      final controller = PetFormController();
      controller.populateForm(const Pet(id: 'p', name: 'Spot', species: 'cat'));
      expect(controller.state.isNeutered, isNull);
    });
  });

  group('PetFormState.copyWith', () {
    test('overrides only the provided fields and preserves the rest', () {
      final original = PetFormState(
        name: 'Rex',
        breed: 'Lab',
        passedAway: false,
      );
      final updated = original.copyWith(name: 'Rexy', passedAway: true);

      expect(updated.name, 'Rexy');
      expect(updated.passedAway, true);
      expect(updated.breed, 'Lab');
    });

    test('returns an equivalent state when nothing is overridden', () {
      final original = PetFormState(name: 'Rex', selectedSpecies: 'dog');
      final copy = original.copyWith();

      expect(copy.name, 'Rex');
      expect(copy.selectedSpecies, 'dog');
    });
  });

  group('PetFormController.submit', () {
    late ProviderContainer container;
    late RecordingPetRepository repository;
    late PetFormController controller;
    late PetFormSubmitDeps deps;

    PetFormSubmitDeps makeDeps(RecordingPetRepository repo) {
      return PetFormSubmitDeps(
        readPets: () => repo.initial,
        addPet:
            ({
              required String name,
              required String species,
              String breed = '',
              DateTime? dateOfBirth,
              double? weight,
              String? gender,
              String bio = '',
              String insurance = '',
              DateTime? neuteredDate,
              bool neuterDismissed = false,
              String chipId = '',
              bool chipDismissed = false,
              String? photoPath,
              String? vetId,
              String? organizationId,
            }) async {
              await repo.addPet(
                Pet(
                  id: 'new-pet',
                  name: name,
                  species: species,
                  breed: breed,
                  dateOfBirth: dateOfBirth,
                  weight: weight,
                  gender: gender,
                  bio: bio,
                  insurance: insurance,
                  neuteredDate: neuteredDate,
                  neuterDismissed: neuterDismissed,
                  chipId: chipId,
                  chipDismissed: chipDismissed,
                  photoPath: photoPath,
                  vetId: vetId,
                  organizationId: organizationId,
                ),
              );
            },
        updatePet: (pet) => repo.updatePet(pet),
      );
    }

    setUp(() {
      repository = RecordingPetRepository();
      container = makeContainer(repo: repository);
      controller = PetFormController();
      deps = makeDeps(repository);
    });

    tearDown(() => container.dispose());

    test('fails when name is empty', () async {
      final outcome = await controller.submit(deps, isEditing: false);
      expect(outcome, isA<PetFormSubmitValidationFailed>());
      expect(
        (outcome as PetFormSubmitValidationFailed).reason,
        PetFormSubmitValidation.nameRequired,
      );
    });

    test('fails when create weight is invalid', () async {
      controller.state = controller.state.copyWith(
        name: 'Bella',
        selectedSpecies: 'Dog',
        newWeight: 'abc',
        showWeightInput: true,
      );
      final outcome = await controller.submit(deps, isEditing: false);
      expect(outcome, isA<PetFormSubmitValidationFailed>());
      expect(
        (outcome as PetFormSubmitValidationFailed).reason,
        PetFormSubmitValidation.invalidWeight,
      );
    });

    test('creates a pet with organization id', () async {
      controller.state = controller.state.copyWith(
        name: 'Bella',
        selectedSpecies: 'Dog',
        selectedOrgId: 'org-1',
      );

      final outcome = await controller.submit(deps, isEditing: false);
      expect(outcome, isA<PetFormSubmitSuccess>());
      expect(repository.added, hasLength(1));
      expect(repository.added.single.name, 'Bella');
      expect(repository.added.single.organizationId, 'org-1');
    });

    test('updates an existing pet', () async {
      final existing = Pet(
        id: 'pet-1',
        name: 'Rex',
        species: 'dog',
        breed: 'Lab',
        colorValue: 0xFF7E57C2,
      );
      repository = RecordingPetRepository(initial: [existing]);
      container.dispose();
      container = makeContainer(repo: repository);
      controller = PetFormController();
      deps = makeDeps(repository);
      controller.state = controller.state.copyWith(
        name: 'Rexy',
        selectedSpecies: 'dog',
        breed: 'Labrador',
        bio: 'Updated bio',
      );

      final outcome = await controller.submit(
        deps,
        isEditing: true,
        petId: 'pet-1',
      );

      expect(outcome, isA<PetFormSubmitSuccess>());
      expect(repository.updated, hasLength(1));
      expect(repository.updated.single.name, 'Rexy');
      expect(repository.updated.single.breed, 'Labrador');
      expect(repository.updated.single.bio, 'Updated bio');
      expect(repository.updated.single.colorValue, 0xFF7E57C2);
    });

    test('fails when editing a pet that is not in the list', () async {
      controller.state = controller.state.copyWith(
        name: 'Ghost',
        selectedSpecies: 'cat',
      );
      final outcome = await controller.submit(
        deps,
        isEditing: true,
        petId: 'missing',
      );
      expect(outcome, isA<PetFormSubmitValidationFailed>());
      expect(
        (outcome as PetFormSubmitValidationFailed).reason,
        PetFormSubmitValidation.petNotFound,
      );
    });
  });
}
