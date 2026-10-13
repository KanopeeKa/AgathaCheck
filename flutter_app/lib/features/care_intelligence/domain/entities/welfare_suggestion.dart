/// Server-persisted welfare guidance row (Agatha care journey PR-06+).
class WelfareSuggestion {
  const WelfareSuggestion({
    required this.id,
    required this.petId,
    required this.subjectKey,
    required this.dedupeKey,
    required this.rationaleKey,
    required this.engineVersion,
    required this.severity,
    this.createdAt,
  });

  final String id;
  final String petId;
  final String subjectKey;
  final String dedupeKey;
  final String rationaleKey;
  final String engineVersion;
  final int severity;
  final DateTime? createdAt;
}
