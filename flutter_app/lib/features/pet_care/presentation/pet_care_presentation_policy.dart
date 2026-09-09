import '../../care_intelligence/domain/entities/care_recommendation.dart';
import '../../care_intelligence/domain/entities/care_safeguard.dart';
import '../progression/domain/entities/care_pending_moment.dart';

/// Centralised arbitration for contextual Pet Care surfaces (profile + dashboard).
///
/// Priority: safeguard > suggestion > milestone moment.
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

  /// Milestone moment when no higher-priority contextual card is active.
  CarePendingMoment? profileMilestoneMoment(
    CarePendingMoment? moment, {
    CareSafeguard? activeSafeguard,
    CareRecommendation? activeSuggestion,
  }) {
    if (activeSafeguard != null || activeSuggestion != null) return null;
    return moment;
  }

  /// Max one progression moment across pets on the dashboard.
  CarePendingMoment? dashboardMilestoneMoment(
    Map<String, CarePendingMoment?> momentsByPetId, {
    CareSafeguard? activeSafeguard,
    CareRecommendation? activeSuggestion,
  }) {
    if (activeSafeguard != null || activeSuggestion != null) return null;
    for (final moment in momentsByPetId.values) {
      if (moment != null) return moment;
    }
    return null;
  }
}
