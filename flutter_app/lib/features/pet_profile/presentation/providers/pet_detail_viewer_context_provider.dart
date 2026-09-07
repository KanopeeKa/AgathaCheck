import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../experience/domain/entities/app_experience.dart';
import '../../../experience/domain/services/experience_eligibility.dart';
import '../../domain/entities/pet.dart';
import '../../domain/services/pet_detail_actions.dart';
import '../providers/pet_providers.dart';

AppExperience _resolveExperience(AsyncValue petsAsync) {
  final pets = petsAsync.valueOrNull as List<Pet>? ?? [];

  final eligibility = ExperienceEligibilityRules.compute(
    pets: pets,
    orgMembershipCount: 0,
  );

  return eligibility.resolveAutoExperience() ?? AppExperience.petCare;
}

/// Resolved pet-detail policy for [petId], or restricted context while inputs load.
final petDetailViewerContextProvider =
    Provider.family<PetDetailContext, String>((ref, petId) {
      final petsAsync = ref.watch(allPetsIncludingOrgProvider);
      final experience = _resolveExperience(petsAsync);

      if (petsAsync.isLoading) {
        return PetDetailContext.restricted(experience: experience);
      }

      if (petsAsync.hasError) {
        return PetDetailContext.restricted(experience: experience);
      }

      final pet = petsAsync.value?.where((p) => p.id == petId).firstOrNull;
      if (pet == null) {
        return PetDetailContext.restricted(experience: experience);
      }

      return PetDetailActions.resolveContext(
        pet: pet,
        experience: experience,
        isOrgAdmin: false,
        policyInputsResolved: true,
      );
    });
