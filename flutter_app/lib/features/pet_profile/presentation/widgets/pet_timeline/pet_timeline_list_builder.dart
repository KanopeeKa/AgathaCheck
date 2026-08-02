import '../../../domain/entities/pet.dart';
import '../../../domain/entities/pet_timeline_segment.dart';
import 'pet_timeline_display_options.dart';

/// Builds the timeline list: synthetic markers + API segments.
///
/// Sorted latest-first by start date. Custody/gap inclusion is controlled by
/// [options] so future phases can enable them without changing the view layer.
List<PetTimelineSegment> buildPetTimelineList({
  required Pet? pet,
  required List<PetTimelineSegment> apiSegments,
  PetTimelineDisplayOptions options = PetTimelineDisplayOptions.v1,
}) {
  final entries = <PetTimelineSegment>[];

  if (pet?.dateOfBirth != null) {
    entries.add(PetTimelineSegment.dateOfBirth(pet!.dateOfBirth!));
  }
  if (pet?.createdAt != null) {
    entries.add(
      PetTimelineSegment.joinedAgatha(
        createdAt: pet!.createdAt!,
        guardianName: pet.guardianName,
      ),
    );
  }

  for (final segment in apiSegments) {
    if (segment.isGap && !options.includeGaps) continue;
    if (segment.isCustody && !options.includeCustody) continue;
    if (segment.isFosteringSession ||
        segment.isManual ||
        (options.includeCustody && segment.isCustody) ||
        (options.includeGaps && segment.isGap)) {
      entries.add(segment);
    }
  }

  entries.sort((a, b) => b.startDate.compareTo(a.startDate));
  return entries;
}
