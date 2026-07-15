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

  test('orgShellPets includes only org inventory pets', () {
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
        organizationId: 'o1',
        organizationName: 'Rescue',
      ),
      const Pet(
        id: '4',
        name: 'Shared',
        species: 'Dog',
        isShared: true,
        organizationName: 'Rescue',
      ),
    ];
    final org = controller.orgShellPets(pets);
    expect(org.map((p) => p.id).toList(), ['2']);
  });

  test('groupSharedPets groups by guardian name then org name', () {
    final pets = [
      const Pet(
        id: '1',
        name: 'A',
        species: 'Cat',
        isShared: true,
        guardianName: 'Alex',
      ),
      const Pet(
        id: '2',
        name: 'B',
        species: 'Dog',
        isShared: true,
        guardianName: 'Alex',
      ),
      const Pet(
        id: '3',
        name: 'C',
        species: 'Cat',
        isShared: true,
        organizationName: 'Rescue',
      ),
    ];
    final groups = controller.groupSharedPets(pets);
    expect(groups.keys, containsAll(['Alex', 'Rescue']));
    expect(groups['Alex']!.map((p) => p.id), ['1', '2']);
    expect(groups['Rescue']!.map((p) => p.id), ['3']);
  });

  test('groupFosteredPets groups by organisation name', () {
    final pets = [
      const Pet(
        id: '1',
        name: 'Foster',
        species: 'Cat',
        isFoster: true,
        organizationName: 'Rescue A',
      ),
      const Pet(
        id: '2',
        name: 'Foster2',
        species: 'Dog',
        isFoster: true,
        organizationName: 'Rescue B',
      ),
    ];
    final groups = controller.groupFosteredPets(pets);
    expect(groups.keys, containsAll(['Rescue A', 'Rescue B']));
  });

  test('getOwnedPets excludes shared and foster pets', () {
    final pets = [
      const Pet(id: '1', name: 'Mine', species: 'Cat'),
      const Pet(id: '2', name: 'Shared', species: 'Dog', isShared: true),
      const Pet(id: '3', name: 'Foster', species: 'Cat', isFoster: true),
    ];
    final owned = controller.getOwnedPets(pets);
    expect(owned.map((p) => p.id), ['1']);
  });
}
