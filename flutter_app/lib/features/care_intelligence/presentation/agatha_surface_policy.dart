import '../domain/profile_completeness_kind.dart';

/// Extended Agatha presentation rules (PR-05): tiebreak, nag budget, cooldown.
class AgathaSurfacePolicy {
  const AgathaSurfacePolicy();

  static const completenessDismissCooldown = Duration(days: 30);

  /// Rhythm beats welfare; then higher [severity]; then oldest [createdAt].
  AgathaGuidanceCandidate? pickProfileGuidance(
    List<AgathaGuidanceCandidate> candidates,
  ) {
    if (candidates.isEmpty) return null;
    final sorted = [...candidates]..sort(_compareGuidance);
    return sorted.first;
  }

  int _compareGuidance(AgathaGuidanceCandidate a, AgathaGuidanceCandidate b) {
    final kindOrder = a.kind.index.compareTo(b.kind.index);
    if (kindOrder != 0) return kindOrder;
    final severity = b.severity.compareTo(a.severity);
    if (severity != 0) return severity;
    return a.createdAt.compareTo(b.createdAt);
  }

  /// True when server dismiss flag is set and still inside the 30d nag budget.
  bool completenessDismissInCooldown({
    required bool dismissedOnPet,
    required DateTime? dismissedAt,
    required DateTime now,
  }) {
    if (!dismissedOnPet) return false;
    if (dismissedAt == null) return true;
    return now.difference(dismissedAt) < completenessDismissCooldown;
  }

  bool shouldOfferCompletenessKind({
    required ProfileCompletenessKind kind,
    required bool statusUnknown,
    required bool dismissedOnPet,
    required DateTime? dismissedAt,
    required DateTime now,
  }) {
    if (!statusUnknown) return false;
    if (completenessDismissInCooldown(
      dismissedOnPet: dismissedOnPet,
      dismissedAt: dismissedAt,
      now: now,
    )) {
      return false;
    }
    return true;
  }
}

enum AgathaGuidanceKind { rhythm, welfare }

class AgathaGuidanceCandidate {
  const AgathaGuidanceCandidate({
    required this.kind,
    required this.severity,
    required this.createdAt,
    required this.id,
  });

  final AgathaGuidanceKind kind;
  final int severity;
  final DateTime createdAt;
  final String id;
}
