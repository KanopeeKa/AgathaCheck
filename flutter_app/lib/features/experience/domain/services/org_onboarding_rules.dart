import '../../../organization/domain/entities/organization.dart';
import '../../../pet_profile/domain/entities/pet.dart';

/// Pure rules for when org super-admin onboarding should appear.
class OrgOnboardingRules {
  const OrgOnboardingRules._();

  static const orgHomePath = '/o/orgs';
  static const onboardingPath = '/o/onboarding';

  /// True when [pet] is org inventory (shelter/organisation-owned, not foster/shared).
  static bool isOrgInventoryPet(Pet pet) {
    return !pet.passedAway &&
        !pet.isFoster &&
        !pet.isShared &&
        pet.organizationId != null &&
        pet.organizationName != null &&
        pet.organizationName!.isNotEmpty;
  }

  static bool hasOrgInventoryPets(List<Pet> pets) {
    for (final pet in pets) {
      if (isOrgInventoryPet(pet)) return true;
    }
    return false;
  }

  /// Foster-portal users use Phase 4.3 flows, not super-admin onboarding.
  static bool isFosterOnlyMembership(List<Organization> orgs) {
    return orgs.isNotEmpty && orgs.every((o) => o.isFoster);
  }

  /// True when the user should see the org super-admin onboarding wizard.
  static bool needsOnboarding({
    required List<Pet> pets,
    required List<Organization> orgs,
    required bool onboardingCompleted,
  }) {
    if (onboardingCompleted) return false;
    if (isFosterOnlyMembership(orgs)) return false;
    if (orgs.isEmpty) return false;
    return !hasOrgInventoryPets(pets);
  }

  static String resolveOrgDestination({
    required String targetPath,
    required List<Pet> pets,
    required List<Organization> orgs,
    required bool onboardingCompleted,
  }) {
    if (targetPath != orgHomePath) return targetPath;
    if (needsOnboarding(
      pets: pets,
      orgs: orgs,
      onboardingCompleted: onboardingCompleted,
    )) {
      return onboardingPath;
    }
    return orgHomePath;
  }
}
