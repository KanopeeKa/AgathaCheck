import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/experience/domain/services/pet_care_onboarding_rules.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';

void main() {
  group('PetCareOnboardingRules', () {
    test('needs onboarding when no owned pets and not completed', () {
      expect(
        PetCareOnboardingRules.needsOnboarding(
          pets: const [],
          onboardingCompleted: false,
        ),
        isTrue,
      );
    });

    test('does not need onboarding when completed', () {
      expect(
        PetCareOnboardingRules.needsOnboarding(
          pets: const [],
          onboardingCompleted: true,
        ),
        isFalse,
      );
    });

    test('does not need onboarding when user owns a pet', () {
      expect(
        PetCareOnboardingRules.needsOnboarding(
          pets: const [Pet(id: '1', name: 'Bella', species: 'Dog')],
          onboardingCompleted: false,
        ),
        isFalse,
      );
    });

    test('shared and foster pets do not skip onboarding', () {
      expect(
        PetCareOnboardingRules.hasOwnedPetCarePets(const [
          Pet(id: '1', name: 'Shared', species: 'Cat', isShared: true),
          Pet(id: '2', name: 'Foster', species: 'Dog', isFoster: true),
        ]),
        isFalse,
      );
    });

    test('org inventory pets do not skip onboarding', () {
      expect(
        PetCareOnboardingRules.hasOwnedPetCarePets(const [
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
        PetCareOnboardingRules.resolvePetCareDestination(
          targetPath: '/pc/home',
          pets: const [],
          onboardingCompleted: false,
        ),
        '/pc/onboarding',
      );
    });

    test('leaves org home unchanged', () {
      expect(
        PetCareOnboardingRules.resolvePetCareDestination(
          targetPath: '/o/orgs',
          pets: const [],
          onboardingCompleted: false,
        ),
        '/o/orgs',
      );
    });
  });
}
