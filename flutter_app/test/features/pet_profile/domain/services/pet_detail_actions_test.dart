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
          experience: AppExperience.petCare,
        ),
        PetViewerRole.fosterCarer,
      );
    });

    test('shared pet is sharedCarer', () {
      expect(
        PetViewerRoleResolver.resolve(
          pet: _pet(isShared: true),
          experience: AppExperience.petCare,
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
          experience: AppExperience.petCare,
        ),
        PetViewerRole.guardian,
      );
    });
  });

  group('PetDetailActions', () {
    test('guardian owner gets full personal actions', () {
      final actions = PetDetailActions.visible(
        pet: _pet(),
        experience: AppExperience.petCare,
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
        experience: AppExperience.petCare,
        role: PetViewerRole.sharedCarer,
      );
      expect(actions, contains(PetDetailAction.downloadReport));
      expect(actions, isNot(contains(PetDetailAction.editProfile)));
      expect(actions, isNot(contains(PetDetailAction.assignVet)));
    });

    test('foster carer can download but not manage sharing', () {
      final actions = PetDetailActions.visible(
        pet: _pet(isFoster: true, organizationName: 'Shelter'),
        experience: AppExperience.petCare,
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

    test('unresolved policy inputs deny all privileged actions', () {
      final actions = PetDetailActions.visible(
        pet: _pet(),
        experience: AppExperience.petCare,
        role: PetViewerRole.guardian,
        policyInputsResolved: false,
      );
      expect(actions, isEmpty);

      final ctx = PetDetailActions.resolveContext(
        pet: _pet(),
        experience: AppExperience.petCare,
        policyInputsResolved: false,
      );
      expect(ctx.isPolicyResolved, isFalse);
      expect(ctx.can(PetDetailAction.editProfile), isFalse);
      expect(ctx.can(PetDetailAction.downloadReport), isFalse);
    });

    test('restricted context factory denies every action', () {
      final ctx = PetDetailContext.restricted();
      expect(ctx.isPolicyResolved, isFalse);
      expect(ctx.actions, isEmpty);
      for (final action in PetDetailAction.values) {
        expect(ctx.can(action), isFalse);
      }
    });
  });

  group('action matrix (experience x role x admin)', () {
    final cases =
        <
          ({
            String label,
            Pet pet,
            AppExperience experience,
            PetViewerRole role,
            bool isOrgAdmin,
            Set<PetDetailAction> expected,
          })
        >[
          (
            label: 'guardian / guardian',
            pet: _pet(),
            experience: AppExperience.petCare,
            role: PetViewerRole.guardian,
            isOrgAdmin: false,
            expected: {
              PetDetailAction.editProfile,
              PetDetailAction.assignVet,
              PetDetailAction.manageSharing,
              PetDetailAction.downloadReport,
            },
          ),
          (
            label: 'guardian / sharedCarer',
            pet: _pet(isShared: true),
            experience: AppExperience.petCare,
            role: PetViewerRole.sharedCarer,
            isOrgAdmin: false,
            expected: {PetDetailAction.downloadReport},
          ),
          (
            label: 'guardian / fosterCarer',
            pet: _pet(isFoster: true, organizationName: 'Shelter'),
            experience: AppExperience.petCare,
            role: PetViewerRole.fosterCarer,
            isOrgAdmin: false,
            expected: {PetDetailAction.downloadReport},
          ),
          (
            label: 'organization / org admin',
            pet: _pet(organizationId: 'o1', organizationName: 'Shelter'),
            experience: AppExperience.organization,
            role: PetViewerRole.organization,
            isOrgAdmin: true,
            expected: {
              PetDetailAction.editProfile,
              PetDetailAction.assignVet,
              PetDetailAction.manageSharing,
              PetDetailAction.fosterPlacement,
              PetDetailAction.downloadReport,
            },
          ),
          (
            label: 'organization / org non-admin',
            pet: _pet(organizationId: 'o1', organizationName: 'Shelter'),
            experience: AppExperience.organization,
            role: PetViewerRole.organization,
            isOrgAdmin: false,
            expected: {PetDetailAction.downloadReport},
          ),
          (
            label: 'organization experience / personal guardian pet',
            pet: _pet(),
            experience: AppExperience.organization,
            role: PetViewerRole.guardian,
            isOrgAdmin: false,
            expected: {
              PetDetailAction.editProfile,
              PetDetailAction.assignVet,
              PetDetailAction.manageSharing,
              PetDetailAction.downloadReport,
            },
          ),
          (
            label: 'guardian experience / org inventory pet',
            pet: _pet(organizationId: 'o1', organizationName: 'Shelter'),
            experience: AppExperience.petCare,
            role: PetViewerRole.guardian,
            isOrgAdmin: false,
            expected: {
              PetDetailAction.editProfile,
              PetDetailAction.assignVet,
              PetDetailAction.manageSharing,
              PetDetailAction.downloadReport,
            },
          ),
        ];

    for (final c in cases) {
      test(c.label, () {
        final actions = PetDetailActions.visible(
          pet: c.pet,
          experience: c.experience,
          role: c.role,
          isOrgAdmin: c.isOrgAdmin,
        );
        expect(actions, c.expected);
      });
    }
  });
}
