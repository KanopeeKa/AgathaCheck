import '../domain/entities/care_recommendation.dart';
import '../domain/entities/care_safeguard.dart';
import 'agatha_surface_policy.dart';

/// Centralised arbitration for care intelligence cards on profile and dashboard.
///
/// Priority: safeguard > suggestion (milestone moments are composed in experience).
class PetCarePresentationPolicy {
  const PetCarePresentationPolicy({AgathaSurfacePolicy? surfacePolicy})
    : _surfacePolicy = surfacePolicy ?? const AgathaSurfacePolicy();

  final AgathaSurfacePolicy _surfacePolicy;

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
    List<AgathaGuidanceCandidate> welfareCandidates = const [],
  }) {
    if (activeSafeguard != null) return null;
    final rhythmCandidates = recommendations
        .where((r) => r.isPending)
        .map(
          (r) => AgathaGuidanceCandidate(
            kind: AgathaGuidanceKind.rhythm,
            severity: 0,
            createdAt: r.respondedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
            id: r.id,
          ),
        )
        .toList();
    final picked = _surfacePolicy.pickProfileGuidance([
      ...rhythmCandidates,
      ...welfareCandidates,
    ]);
    if (picked == null || picked.kind != AgathaGuidanceKind.rhythm) {
      return null;
    }
    return recommendations
        .where((r) => r.isPending && r.id == picked.id)
        .firstOrNull;
  }

  CareRecommendation? dashboardSuggestion(
    Map<String, List<CareRecommendation>> recommendationsByPetId, {
    CareSafeguard? activeSafeguard,
    List<AgathaGuidanceCandidate> welfareCandidates = const [],
  }) {
    if (activeSafeguard != null) return null;
    final rhythmCandidates = <AgathaGuidanceCandidate>[];
    for (final entries in recommendationsByPetId.values) {
      for (final r in entries.where((r) => r.isPending)) {
        rhythmCandidates.add(
          AgathaGuidanceCandidate(
            kind: AgathaGuidanceKind.rhythm,
            severity: 0,
            createdAt: r.respondedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
            id: r.id,
          ),
        );
      }
    }
    final picked = _surfacePolicy.pickProfileGuidance([
      ...rhythmCandidates,
      ...welfareCandidates,
    ]);
    if (picked == null || picked.kind != AgathaGuidanceKind.rhythm) {
      return null;
    }
    for (final entries in recommendationsByPetId.values) {
      final match = entries
          .where((r) => r.isPending && r.id == picked.id)
          .firstOrNull;
      if (match != null) return match;
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
}
