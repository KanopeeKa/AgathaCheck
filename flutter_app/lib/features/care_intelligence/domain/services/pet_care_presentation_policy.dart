import '../entities/care_recommendation.dart';
import '../entities/care_safeguard.dart';

/// Centralised suppression for contextual Pet Care surfaces (profile + dashboard).
class PetCarePresentationPolicy {
  const PetCarePresentationPolicy();

  CareSafeguard? profileSafeguard(List<CareSafeguard> safeguards) {
    return safeguards.where((s) => s.isActive).firstOrNull;
  }

  /// Pet profile may show at most one prominent suggestion card when no safeguard.
  CareRecommendation? profileSuggestion(
    List<CareRecommendation> recommendations, {
    CareSafeguard? activeSafeguard,
  }) {
    if (activeSafeguard != null) return null;
    return recommendations.where((r) => r.isPending).firstOrNull;
  }

  /// Dashboard may show at most one suggestion across all pets when no safeguard.
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
}
