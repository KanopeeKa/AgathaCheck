import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/controllers/pet_list_controller.dart';

void main() {
  final controller = PetListController();

  test('guardianShellPets excludes org inventory only pets', () {
    final pets = [
      const Pet(id: '1', name: 'Mine', species: 'Cat'),
      const Pet(
        id: '2',
        name: 'Shelter',
        species: 'Dog',
        organizationId: 'o1',
        organizationName: 'Rescue',
      ),
      const Pet(
        id: '3',
        name: 'Foster',
        species: 'Cat',
        isFoster: true,
        organizationName: 'Rescue',
      ),
    ];
    final shell = controller.guardianShellPets(pets);
    expect(shell.map((p) => p.id).toList(), ['1', '3']);
  });
}
