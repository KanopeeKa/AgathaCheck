/// Controls which segment kinds appear in the pet timeline list.
class PetTimelineDisplayOptions {
  const PetTimelineDisplayOptions({
    this.includeCustody = false,
    this.includeGaps = false,
  });

  final bool includeCustody;
  final bool includeGaps;

  /// Legacy list-only segments (fostering + manual + synthetic markers).
  static const v1 = PetTimelineDisplayOptions();

  /// Full composite timeline from the API (custody, gaps, fostering, manual).
  static const full = PetTimelineDisplayOptions(
    includeCustody: true,
    includeGaps: true,
  );
}
