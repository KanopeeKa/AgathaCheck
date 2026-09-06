import '../../../pet_profile/domain/entities/pet.dart';

/// Pure rules for when guardian onboarding should appear.
class PetCareOnboardingRules {
  const PetCareOnboardingRules._();

  static const petCareHomePath = '/pc/home';
  static const onboardingPath = '/pc/onboarding';

  /// True when [pet] is an owned personal guardian pet (not shared/foster/org).
  static bool isOwnedPetCarePet(Pet pet) {
    if (pet.passedAway || pet.isShared || pet.isFoster) return false;
    return pet.organizationId == null ||
        pet.organizationName == null ||
        pet.organizationName!.isEmpty;
  }

  /// True when the user has at least one owned personal guardian pet.
  static bool hasOwnedPetCarePets(List<Pet> pets) {
    for (final pet in pets) {
      if (isOwnedPetCarePet(pet)) return true;
    }
    return false;
  }

  /// True when the user should see the guardian onboarding wizard.
  static bool needsOnboarding({
    required List<Pet> pets,
    required bool onboardingCompleted,
  }) {
    if (onboardingCompleted) return false;
    return !hasOwnedPetCarePets(pets);
  }

  /// Maps a resolved guardian home path to onboarding when needed.
  static String resolvePetCareDestination({
    required String targetPath,
    required List<Pet> pets,
    required bool onboardingCompleted,
  }) {
    if (targetPath != petCareHomePath) return targetPath;
    if (needsOnboarding(pets: pets, onboardingCompleted: onboardingCompleted)) {
      return onboardingPath;
    }
    return petCareHomePath;
  }
}
