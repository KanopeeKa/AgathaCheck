import '../../../pet_profile/domain/entities/pet.dart';
import '../entities/app_experience.dart';

/// Whether the signed-in user may open each experience shell.
class ExperienceEligibility {
  const ExperienceEligibility({
    required this.hasOrgMembership,
    required this.hasGuardianContext,
  });

  final bool hasOrgMembership;
  final bool hasGuardianContext;

  bool get canUseGuardian => hasGuardianContext || !hasOrgMembership;

  bool get canUseOrganization => hasOrgMembership;

  bool get showChooser => canUseGuardian && canUseOrganization;

  List<AppExperience> get availableExperiences {
    final list = <AppExperience>[];
    if (canUseGuardian) list.add(AppExperience.petCare);
    if (canUseOrganization) list.add(AppExperience.organization);
    return list;
  }

  AppExperience? resolveAutoExperience({AppExperience? savedDefault}) {
    if (showChooser) {
      if (savedDefault != null && availableExperiences.contains(savedDefault)) {
        return savedDefault;
      }
      return null;
    }
    if (canUseOrganization && !canUseGuardian) {
      return AppExperience.organization;
    }
    return AppExperience.petCare;
  }
}

/// Pure helpers for eligibility from pets + org list length.
class ExperienceEligibilityRules {
  const ExperienceEligibilityRules._();

  static bool hasGuardianContextFromPets(List<Pet> pets) {
    for (final pet in pets) {
      if (_isGuardianContextPet(pet)) return true;
    }
    return false;
  }

  static bool _isGuardianContextPet(Pet pet) {
    if (pet.isFoster || pet.isShared) return true;
    if (pet.organizationId == null) return true;
    if (pet.organizationName == null || pet.organizationName!.isEmpty) {
      return true;
    }
    return false;
  }

  static ExperienceEligibility compute({
    required List<Pet> pets,
    required int orgMembershipCount,
  }) {
    final hasOrg = orgMembershipCount > 0;
    final hasGuardian = hasOrg ? hasGuardianContextFromPets(pets) : true;
    return ExperienceEligibility(
      hasOrgMembership: hasOrg,
      hasGuardianContext: hasGuardian,
    );
  }
}
