import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../experience/domain/entities/app_experience.dart';
import '../../../experience/domain/services/experience_eligibility.dart';
import '../../../organization/domain/entities/organization.dart';
import '../../../organization/presentation/providers/organization_providers.dart';
import '../../domain/entities/pet.dart';
import '../../domain/services/pet_detail_actions.dart';
import '../providers/pet_providers.dart';

AppExperience _resolveExperience(AsyncValue petsAsync, AsyncValue orgsAsync) {
  final pets = petsAsync.valueOrNull as List<Pet>? ?? [];
  final orgs = orgsAsync.valueOrNull as List<Organization>? ?? [];

  final eligibility = ExperienceEligibilityRules.compute(
    pets: pets,
    orgMembershipCount: orgs.length,
  );

  return eligibility.resolveAutoExperience() ?? AppExperience.guardian;
}

/// Resolved pet-detail policy for [petId], or restricted context while inputs load.
final petDetailViewerContextProvider =
    Provider.family<PetDetailContext, String>((ref, petId) {
      final petsAsync = ref.watch(allPetsIncludingOrgProvider);
      final orgsAsync = ref.watch(organizationListProvider);
      final experience = _resolveExperience(petsAsync, orgsAsync);

      if (petsAsync.isLoading || orgsAsync.isLoading) {
        return PetDetailContext.restricted(experience: experience);
      }

      if (petsAsync.hasError || orgsAsync.hasError) {
        return PetDetailContext.restricted(experience: experience);
      }

      final pet = petsAsync.value?.where((p) => p.id == petId).firstOrNull;
      if (pet == null) {
        return PetDetailContext.restricted(experience: experience);
      }

      final isOrgAdmin = pet.organizationId != null
          ? ref.watch(isOrgAdminProvider(pet.organizationId!))
          : false;

      return PetDetailActions.resolveContext(
        pet: pet,
        experience: experience,
        isOrgAdmin: isOrgAdmin,
        policyInputsResolved: true,
      );
    });
