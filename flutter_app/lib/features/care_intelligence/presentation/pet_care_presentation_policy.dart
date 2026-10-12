import '../domain/entities/care_recommendation.dart';
import '../domain/entities/care_safeguard.dart';
import '../domain/profile_completeness_kind.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/pet.dart';
import 'package:pet_profile_app/features/pet_profile/domain/entities/profile_fact_status.dart';
import 'package:pet_profile_app/core/utils/constants.dart';

/// Centralised arbitration for care intelligence cards on profile and dashboard.
///
/// Priority: safeguard > suggestion (milestone moments are composed in experience).
class PetCarePresentationPolicy {
  const PetCarePresentationPolicy();

  CareSafeguard? profileSafeguard(List<CareSafeguard> safeguards) {
    return safeguards.where((s) => s.isActive).firstOrNull;
  }

  CareSafeguard? dashboardSafeguard(
    Map<String, List<CareSafeguard>> safeguardsByPetId,
  ) {
    for (final entries in safeguardsByPetId.values) {
      final active = entries.where((s) => s.isActive).firstOrNull;
      if (active != null) return active;
    }
    return null;
  }

  CareRecommendation? profileSuggestion(
    List<CareRecommendation> recommendations, {
    CareSafeguard? activeSafeguard,
  }) {
    if (activeSafeguard != null) return null;
    return recommendations.where((r) => r.isPending).firstOrNull;
  }

  CareRecommendation? dashboardSuggestion(
    Map<String, List<CareRecommendation>> recommendationsByPetId, {
    CareSafeguard? activeSafeguard,
  }) {
    if (activeSafeguard != null) return null;
    for (final entries in recommendationsByPetId.values) {
      final pending = entries.where((r) => r.isPending).firstOrNull;
      if (pending != null) return pending;
    }
    return null;
  }

  /// PR-04 minimal slot policy: completeness does not stack with safeguard or
  /// guidance (rhythm suggestion or milestone moment in the same slot).
  bool profileCompletenessSlotAvailable({
    CareSafeguard? activeSafeguard,
    CareRecommendation? activeSuggestion,
    required bool guidanceMomentVisible,
  }) {
    if (activeSafeguard != null) return false;
    if (activeSuggestion != null) return false;
    if (guidanceMomentVisible) return false;
    return true;
  }

  List<ProfileCompletenessKind> profileCompletenessCandidates(Pet pet) {
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
}
