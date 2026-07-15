import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/domain/entities/app_experience.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet_viewer_role.dart';
import 'package:pet_profile_app/features/pet_profile/domain/services/pet_detail_actions.dart';

Pet _pet({
  bool isShared = false,
  bool isFoster = false,
  String? organizationId,
  String? organizationName,
}) {
  return Pet(
    id: 'p1',
    name: 'Max',
    species: 'Dog',
    isShared: isShared,
    isFoster: isFoster,
    organizationId: organizationId,
    organizationName: organizationName,
  );
}

void main() {
  group('PetViewerRoleResolver', () {
    test('foster pet is fosterCarer regardless of experience', () {
      expect(
        PetViewerRoleResolver.resolve(
          pet: _pet(isFoster: true, organizationName: 'Shelter'),
          experience: AppExperience.guardian,
        ),
        PetViewerRole.fosterCarer,
      );
    });

    test('shared pet is sharedCarer', () {
      expect(
        PetViewerRoleResolver.resolve(
          pet: _pet(isShared: true),
          experience: AppExperience.guardian,
        ),
        PetViewerRole.sharedCarer,
      );
    });

    test('org inventory pet in org experience is organization role', () {
      expect(
        PetViewerRoleResolver.resolve(
          pet: _pet(organizationId: 'o1', organizationName: 'Shelter'),
          experience: AppExperience.organization,
        ),
        PetViewerRole.organization,
      );
    });

    test('org inventory pet in guardian experience stays guardian role', () {
      expect(
        PetViewerRoleResolver.resolve(
          pet: _pet(organizationId: 'o1', organizationName: 'Shelter'),
          experience: AppExperience.guardian,
        ),
        PetViewerRole.guardian,
      );
    });
  });

  group('PetDetailActions', () {
    test('guardian owner gets full personal actions', () {
      final actions = PetDetailActions.visible(
        pet: _pet(),
        experience: AppExperience.guardian,
        role: PetViewerRole.guardian,
      );
      expect(actions, contains(PetDetailAction.editProfile));
      expect(actions, contains(PetDetailAction.assignVet));
      expect(actions, contains(PetDetailAction.manageSharing));
      expect(actions, isNot(contains(PetDetailAction.fosterPlacement)));
    });

    test('shared carer can download but not edit or assign vet', () {
      final actions = PetDetailActions.visible(
        pet: _pet(isShared: true),
        experience: AppExperience.guardian,
        role: PetViewerRole.sharedCarer,
      );
      expect(actions, contains(PetDetailAction.downloadReport));
      expect(actions, isNot(contains(PetDetailAction.editProfile)));
      expect(actions, isNot(contains(PetDetailAction.assignVet)));
    });

    test('foster carer can download but not manage sharing', () {
      final actions = PetDetailActions.visible(
        pet: _pet(isFoster: true, organizationName: 'Shelter'),
        experience: AppExperience.guardian,
        role: PetViewerRole.fosterCarer,
      );
      expect(actions, contains(PetDetailAction.downloadReport));
      expect(actions, isNot(contains(PetDetailAction.manageSharing)));
    });

    test('org admin on org pet gets placement and edit actions', () {
      final actions = PetDetailActions.visible(
        pet: _pet(organizationId: 'o1', organizationName: 'Shelter'),
        experience: AppExperience.organization,
        role: PetViewerRole.organization,
        isOrgAdmin: true,
      );
      expect(actions, contains(PetDetailAction.fosterPlacement));
      expect(actions, contains(PetDetailAction.editProfile));
    });

    test('non-admin org viewer only gets download', () {
      final actions = PetDetailActions.visible(
        pet: _pet(organizationId: 'o1', organizationName: 'Shelter'),
        experience: AppExperience.organization,
        role: PetViewerRole.organization,
        isOrgAdmin: false,
      );
      expect(actions, {PetDetailAction.downloadReport});
    });
  });
}
