import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/presentation/controllers/pet_list_controller.dart';

Pet _pet({
  required String id,
  bool isShared = false,
  bool isFoster = false,
  String? organizationId,
  String? organizationName,
  bool passedAway = false,
}) {
  return Pet(
    id: id,
    name: 'Pet $id',
    species: 'dog',
    isShared: isShared,
    isFoster: isFoster,
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

  test('fostered pets appear in fostered active list, not personal or org', () {
    final controller = PetListController();
    final fostered = _pet(
      id: 'foster-1',
      isFoster: true,
      organizationId: 'org-1',
      organizationName: 'Shelter A',
    );

    expect(controller.getFosteredActive([fostered]), hasLength(1));
    expect(controller.getPersonalActive([fostered]), isEmpty);
    expect(controller.getOrgGroups([fostered]), isEmpty);
  });

  test('fostered filter chip shows only fostered pets', () {
    final controller = PetListController()..orgFilter = '_fostered';
    final fostered = _pet(
      id: 'foster-1',
      isFoster: true,
      organizationId: 'org-1',
      organizationName: 'Shelter A',
    );
    final owned = _pet(id: 'owned-1');

    final filtered = controller.filterPets([fostered, owned]);

    expect(filtered, hasLength(1));
    expect(filtered.single.id, 'foster-1');
  });

  test('org filter excludes fostered pets from organisation inventory', () {
    final controller = PetListController()..orgFilter = 'Shelter A';
    final fostered = _pet(
      id: 'foster-1',
      isFoster: true,
      organizationId: 'org-1',
      organizationName: 'Shelter A',
    );
    final orgPet = _pet(
      id: 'org-1',
      organizationId: 'org-1',
      organizationName: 'Shelter A',
    );

    final filtered = controller.filterPets([fostered, orgPet]);

    expect(filtered, hasLength(1));
    expect(filtered.single.id, 'org-1');
  });

  test('passed-away fostered pets are tracked separately from org groups', () {
    final controller = PetListController();
    final fosteredPassed = _pet(
      id: 'foster-passed',
      isFoster: true,
      organizationId: 'org-1',
      organizationName: 'Shelter A',
      passedAway: true,
    );

    expect(controller.getFosteredPassed([fosteredPassed]), hasLength(1));
    expect(controller.getOrgPassedGroups([fosteredPassed]), isEmpty);
    expect(
      controller.getAllPassedAway([], [fosteredPassed], {}),
      hasLength(1),
    );
  });

  test('syncOrgFilter clears stale organisation filter', () {
    final controller = PetListController()..orgFilter = 'Old Org';

    controller.syncOrgFilter(['Current Org']);

    expect(controller.orgFilter, isNull);
  });

  test('syncOrgFilter keeps valid organisation filter', () {
    final controller = PetListController()..orgFilter = 'Current Org';

    controller.syncOrgFilter(['Current Org', 'Other Org']);

    expect(controller.orgFilter, 'Current Org');
  });

  test('syncOrgFilter keeps personal filter', () {
    final controller = PetListController()..orgFilter = '_personal';

    controller.syncOrgFilter([]);

    expect(controller.orgFilter, '_personal');
  });

  test('syncOrgFilter keeps fostered filter', () {
    final controller = PetListController()..orgFilter = '_fostered';

    controller.syncOrgFilter([]);

    expect(controller.orgFilter, '_fostered');
  });
}
