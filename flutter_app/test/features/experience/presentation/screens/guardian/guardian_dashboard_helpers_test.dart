import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/controllers/pet_list_controller.dart';
import 'package:pet_profile_app/features/experience/presentation/screens/guardian/guardian_dashboard_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final controller = PetListController();

  test('guardianDashboardPreviewPets caps at 4 active shell pets', () {
    final pets = List.generate(
      6,
      (i) => Pet(id: '$i', name: 'Pet $i', species: 'Dog', breed: ''),
    );

    final preview = guardianDashboardPreviewPets(pets, controller, limit: 4);
    expect(preview.length, 4);
  });

  test('guardianDashboardHasMorePets is true when more than 4 active pets', () {
    final pets = List.generate(
      6,
      (i) => Pet(id: '$i', name: 'Pet $i', species: 'Dog', breed: ''),
    );

    expect(guardianDashboardHasMorePets(pets, controller, limit: 4), isTrue);
  });

  test('passed-away pets are excluded from preview', () {
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

    final preview = guardianDashboardPreviewPets(pets, controller);
    expect(preview.length, 1);
    expect(preview.first.name, 'Alive');
  });
}
