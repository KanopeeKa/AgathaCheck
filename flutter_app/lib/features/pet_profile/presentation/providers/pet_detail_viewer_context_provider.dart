import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/experience/app_experience.dart';
import '../../domain/services/pet_detail_actions.dart';
import '../providers/pet_providers.dart';

AppExperience _resolveExperience(AsyncValue petsAsync) {
  // Pet detail is guardian-shell scoped; org membership is not resolved here.
  return AppExperience.petCare;
}

/// Resolved pet-detail policy for [petId], or restricted context while inputs load.
final petDetailViewerContextProvider =
    Provider.family<PetDetailContext, String>((ref, petId) {
      final petsAsync = ref.watch(allPetsIncludingOrgProvider);
      final listAsync = ref.watch(petListProvider);
      final experience = _resolveExperience(petsAsync);

      Pet? pet = petsAsync.value?.where((p) => p.id == petId).firstOrNull;
      if (pet == null && listAsync.hasValue) {
        pet = listAsync.value?.where((p) => p.id == petId).firstOrNull;
      }

      if (pet == null) {
        if (petsAsync.isLoading || listAsync.isLoading) {
          return PetDetailContext.restricted(experience: experience);
        }
        if (petsAsync.hasError && listAsync.hasError) {
          return PetDetailContext.restricted(experience: experience);
        }
        return PetDetailContext.restricted(experience: experience);
      }

      return PetDetailActions.resolveContext(
        pet: pet,
        experience: experience,
        isOrgAdmin: false,
        policyInputsResolved: true,
      );
    });
