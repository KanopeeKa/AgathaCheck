/// Controls which segment kinds appear in the pet timeline list.
///
/// V1 excludes custody and gap placeholders; flip flags when those UIs ship.
class PetTimelineDisplayOptions {
  const PetTimelineDisplayOptions({
    this.includeCustody = false,
    this.includeGaps = false,
  });

  final bool includeCustody;
  final bool includeGaps;

  static const v1 = PetTimelineDisplayOptions();
}
