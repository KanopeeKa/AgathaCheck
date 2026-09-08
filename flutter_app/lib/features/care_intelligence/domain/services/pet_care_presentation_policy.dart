import '../entities/care_recommendation.dart';

/// Centralised suppression for suggestion surfaces (profile + dashboard).
class PetCarePresentationPolicy {
  const PetCarePresentationPolicy();

  /// Pet profile may show at most one prominent suggestion card.
  CareRecommendation? profileSuggestion(
    List<CareRecommendation> recommendations,
  ) {
    return recommendations.where((r) => r.isPending).firstOrNull;
  }

  /// Dashboard may show at most one suggestion across all pets.
  CareRecommendation? dashboardSuggestion(
    Map<String, List<CareRecommendation>> recommendationsByPetId,
  ) {
    for (final entries in recommendationsByPetId.values) {
      final pending = entries.where((r) => r.isPending).firstOrNull;
      if (pending != null) return pending;
    }
    return null;
  }
}
