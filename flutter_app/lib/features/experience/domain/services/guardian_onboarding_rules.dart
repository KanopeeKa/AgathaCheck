import '../../../pet_profile/domain/entities/pet.dart';

/// Pure rules for when guardian onboarding should appear.
class GuardianOnboardingRules {
  const GuardianOnboardingRules._();

  static const guardianHomePath = '/g/home';
  static const onboardingPath = '/g/onboarding';

  /// True when [pet] is an owned personal guardian pet (not shared/foster/org).
  static bool isOwnedGuardianPet(Pet pet) {
    if (pet.passedAway || pet.isShared || pet.isFoster) return false;
    return pet.organizationId == null ||
        pet.organizationName == null ||
        pet.organizationName!.isEmpty;
  }

  /// True when the user has at least one owned personal guardian pet.
  static bool hasOwnedGuardianPets(List<Pet> pets) {
    for (final pet in pets) {
      if (isOwnedGuardianPet(pet)) return true;
    }
    return false;
  }

  /// True when the user should see the guardian onboarding wizard.
  static bool needsOnboarding({
    required List<Pet> pets,
    required bool onboardingCompleted,
  }) {
    if (onboardingCompleted) return false;
    return !hasOwnedGuardianPets(pets);
  }

  /// Maps a resolved guardian home path to onboarding when needed.
  static String resolveGuardianDestination({
    required String targetPath,
    required List<Pet> pets,
    required bool onboardingCompleted,
  }) {
    if (targetPath != guardianHomePath) return targetPath;
    if (needsOnboarding(pets: pets, onboardingCompleted: onboardingCompleted)) {
      return onboardingPath;
    }
    return guardianHomePath;
  }
}
