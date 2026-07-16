import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/domain/services/org_onboarding_rules.dart';
import 'package:pet_profile_app/features/organization/domain/entities/organization.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';

void main() {
  group('OrgOnboardingRules', () {
    const org = Organization(
      id: 'o1',
      name: 'Rescue Hearts',
      type: OrganizationType.charity,
      role: 'super_admin',
    );

    const inventoryPet = Pet(
      id: '1',
      name: 'Shelter',
      species: 'Dog',
      organizationId: 'o1',
      organizationName: 'Rescue Hearts',
    );

    test('needs onboarding when no orgs and not completed', () {
      expect(
        OrgOnboardingRules.needsOnboarding(
          pets: const [],
          orgs: const [],
          onboardingCompleted: false,
        ),
        isTrue,
      );
    });

    test('needs onboarding when org exists but no inventory pets', () {
      expect(
        OrgOnboardingRules.needsOnboarding(
          pets: const [],
          orgs: const [org],
          onboardingCompleted: false,
        ),
        isTrue,
      );
    });

    test('does not need onboarding when completed', () {
      expect(
        OrgOnboardingRules.needsOnboarding(
          pets: const [],
          orgs: const [org],
          onboardingCompleted: true,
        ),
        isFalse,
      );
    });

    test('does not need onboarding when org has inventory pet', () {
      expect(
        OrgOnboardingRules.needsOnboarding(
          pets: const [inventoryPet],
          orgs: const [org],
          onboardingCompleted: false,
        ),
        isFalse,
      );
    });

    test('foster-only membership skips onboarding', () {
      expect(
        OrgOnboardingRules.needsOnboarding(
          pets: const [],
          orgs: const [
            Organization(
              id: 'o1',
              name: 'Rescue Hearts',
              type: OrganizationType.charity,
              role: 'foster',
            ),
          ],
          onboardingCompleted: false,
        ),
        isFalse,
      );
    });

    test('shared and foster pets do not count as inventory', () {
      expect(
        OrgOnboardingRules.hasOrgInventoryPets(const [
          Pet(id: '1', name: 'Shared', species: 'Cat', isShared: true),
          Pet(id: '2', name: 'Foster', species: 'Dog', isFoster: true),
        ]),
        isFalse,
      );
    });

    test('redirects org home to onboarding when needed', () {
      expect(
        OrgOnboardingRules.resolveOrgDestination(
          targetPath: '/o/home',
          pets: const [],
          orgs: const [org],
          onboardingCompleted: false,
        ),
        '/o/onboarding',
      );
    });

    test('leaves guardian home unchanged', () {
      expect(
        OrgOnboardingRules.resolveOrgDestination(
          targetPath: '/g/home',
          pets: const [],
          orgs: const [org],
          onboardingCompleted: false,
        ),
        '/g/home',
      );
    });
  });
}
