import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/controllers/pet_form_controller.dart';

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
      final original = PetFormState(name: 'Rex', breed: 'Lab', passedAway: false);
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
}
