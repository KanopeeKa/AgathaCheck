/// A photo or PDF attached to a health entry or health issue.
class HealthDocument {
  const HealthDocument({
    required this.id,
    required this.url,
    this.healthEntryId,
    this.healthIssueId,
    this.occurrenceId,
    this.caption = '',
  });

  final String id;
  final String url;
  final String? healthEntryId;
  final String? healthIssueId;
  final String? occurrenceId;
  final String caption;
}
