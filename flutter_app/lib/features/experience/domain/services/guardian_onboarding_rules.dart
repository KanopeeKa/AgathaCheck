import '../../../pet_profile/domain/entities/pet.dart';
import '../../../pet_profile/presentation/controllers/pet_list_controller.dart';

/// Pure rules for when guardian onboarding should appear.
class GuardianOnboardingRules {
  const GuardianOnboardingRules._();

  static const guardianHomePath = '/g/home';
  static const onboardingPath = '/g/onboarding';

  /// True when the user should see the guardian onboarding wizard.
  static bool needsOnboarding({
    required List<Pet> pets,
    required bool onboardingCompleted,
  }) {
    if (onboardingCompleted) return false;
    final controller = PetListController();
    final owned = controller.getOwnedPets(controller.guardianShellPets(pets));
    return owned.isEmpty;
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
