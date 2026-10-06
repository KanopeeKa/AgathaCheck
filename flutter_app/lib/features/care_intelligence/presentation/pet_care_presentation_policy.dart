import '../domain/entities/care_recommendation.dart';
import '../domain/entities/care_safeguard.dart';

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
}
