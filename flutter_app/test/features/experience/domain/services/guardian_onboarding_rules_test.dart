import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/domain/services/guardian_onboarding_rules.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';

void main() {
  group('GuardianOnboardingRules', () {
    test('needs onboarding when no owned pets and not completed', () {
      expect(
        GuardianOnboardingRules.needsOnboarding(
          pets: const [],
          onboardingCompleted: false,
        ),
        isTrue,
      );
    });

    test('does not need onboarding when completed', () {
      expect(
        GuardianOnboardingRules.needsOnboarding(
          pets: const [],
          onboardingCompleted: true,
        ),
        isFalse,
      );
    });

    test('does not need onboarding when user owns a pet', () {
      expect(
        GuardianOnboardingRules.needsOnboarding(
          pets: const [Pet(id: '1', name: 'Bella', species: 'Dog')],
          onboardingCompleted: false,
        ),
        isFalse,
      );
    });

    test('shared and foster pets do not skip onboarding', () {
      expect(
        GuardianOnboardingRules.hasOwnedGuardianPets(const [
          Pet(id: '1', name: 'Shared', species: 'Cat', isShared: true),
          Pet(id: '2', name: 'Foster', species: 'Dog', isFoster: true),
        ]),
        isFalse,
      );
    });

    test('org inventory pets do not skip onboarding', () {
      expect(
        GuardianOnboardingRules.hasOwnedGuardianPets(const [
          Pet(
            id: '1',
            name: 'Shelter',
            species: 'Dog',
            organizationId: 'o1',
            organizationName: 'Rescue',
          ),
        ]),
        isFalse,
      );
    });

    test('redirects guardian home to onboarding when needed', () {
      expect(
        GuardianOnboardingRules.resolveGuardianDestination(
          targetPath: '/g/home',
          pets: const [],
          onboardingCompleted: false,
        ),
        '/g/onboarding',
      );
    });

    test('leaves org home unchanged', () {
      expect(
        GuardianOnboardingRules.resolveGuardianDestination(
          targetPath: '/o/home',
          pets: const [],
          onboardingCompleted: false,
        ),
        '/o/home',
      );
    });
  });
}
