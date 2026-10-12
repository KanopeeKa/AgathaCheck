import 'package:pet_profile_app/core/utils/constants.dart';
import 'package:pet_profile_app/features/care_intelligence/domain/profile_completeness_kind.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/profile_fact_status.dart';

/// Which Agatha completeness cards apply for [pet] (experience layer — avoids R6).
List<ProfileCompletenessKind> profileCompletenessKindsForPet(Pet pet) {
  final kinds = <ProfileCompletenessKind>[];
  if (pet.neuterStatus == profileFactStatusUnknown &&
      !pet.neuterDismissed &&
      !AppConstants.speciesWithoutNeutering.contains(pet.species)) {
    kinds.add(ProfileCompletenessKind.neuter);
  }
  if (pet.identificationStatus == profileFactStatusUnknown &&
      !pet.chipDismissed) {
    kinds.add(ProfileCompletenessKind.chip);
  }
  return kinds;
}
