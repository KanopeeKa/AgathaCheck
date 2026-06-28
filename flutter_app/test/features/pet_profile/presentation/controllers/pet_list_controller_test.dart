import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/controllers/pet_list_controller.dart';

Pet _pet({
  required String id,
  bool isShared = false,
  String? organizationId,
  String? organizationName,
  bool passedAway = false,
}) {
  return Pet(
    id: id,
    name: 'Pet $id',
    species: 'dog',
    isShared: isShared,
    organizationId: organizationId,
    organizationName: organizationName,
    passedAway: passedAway,
  );
}

void main() {
  test('shared pets always appear in personal active list', () {
    final controller = PetListController();
    final shared = _pet(
      id: 'shared-1',
      isShared: true,
      organizationId: 'org-1',
      organizationName: 'Owner Org',
    );

    final personal = controller.getPersonalActive([shared]);

    expect(personal, hasLength(1));
    expect(personal.single.id, 'shared-1');
  });

  test('shared pets are excluded from organisation filter groups', () {
    final controller = PetListController()..orgFilter = 'Owner Org';
    final shared = _pet(
      id: 'shared-1',
      isShared: true,
      organizationId: 'org-1',
      organizationName: 'Owner Org',
    );

    final filtered = controller.filterPets([shared]);

    expect(filtered, isEmpty);
  });

  test('shared pets remain visible under the personal filter chip', () {
    final controller = PetListController()..orgFilter = '_personal';
    final shared = _pet(
      id: 'shared-1',
      isShared: true,
      organizationId: 'org-1',
      organizationName: 'Owner Org',
    );

    final filtered = controller.filterPets([shared]);

    expect(filtered, hasLength(1));
  });
}
