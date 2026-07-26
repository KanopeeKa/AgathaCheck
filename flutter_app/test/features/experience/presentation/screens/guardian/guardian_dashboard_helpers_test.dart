import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/controllers/pet_list_controller.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/guardian/guardian_dashboard_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final controller = PetListController();

  test(
    'guardianDashboardPersonalPets returns all active personal pets sorted',
    () {
      final pets = [
        Pet(
          id: '2',
          name: 'Beta',
          species: 'Dog',
          breed: '',
          createdAt: DateTime(2024, 2, 1),
        ),
        Pet(
          id: '1',
          name: 'Alpha',
          species: 'Dog',
          breed: '',
          createdAt: DateTime(2024, 1, 1),
        ),
        Pet(
          id: '3',
          name: 'Foster',
          species: 'Cat',
          breed: '',
          isFoster: true,
          createdAt: DateTime(2024, 3, 1),
        ),
      ];

      final personal = guardianDashboardPersonalPets(pets, controller);
      expect(personal.length, 2);
      expect(personal.map((p) => p.name).toList(), ['Alpha', 'Beta']);
    },
  );

  test('guardianDashboardFosterPets returns foster pets only', () {
    final pets = [
      const Pet(id: '1', name: 'Mine', species: 'Dog', breed: ''),
      const Pet(
        id: '2',
        name: 'Fostered',
        species: 'Cat',
        breed: '',
        isFoster: true,
      ),
    ];

    final fostered = guardianDashboardFosterPets(pets, controller);
    expect(fostered.length, 1);
    expect(fostered.first.name, 'Fostered');
  });

  test('passed-away pets are excluded from dashboard groups', () {
    final pets = [
      const Pet(
        id: '1',
        name: 'Alive',
        species: 'Dog',
        breed: '',
        passedAway: false,
      ),
      const Pet(
        id: '2',
        name: 'Gone',
        species: 'Dog',
        breed: '',
        passedAway: true,
      ),
    ];

    expect(guardianDashboardPersonalPets(pets, controller).length, 1);
    expect(guardianDashboardHasAnyPets(pets, controller), isTrue);
  });
}
