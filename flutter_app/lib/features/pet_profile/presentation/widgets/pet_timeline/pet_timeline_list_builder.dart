import '../../../domain/entities/pet.dart';
import '../../../domain/entities/pet_timeline_segment.dart';

/// Builds the v1 timeline list: synthetic markers + fostering + manual entries.
///
/// Excludes custody segments and gap placeholders. Sorted latest-first by start date.
List<PetTimelineSegment> buildPetTimelineList({
  required Pet? pet,
  required List<PetTimelineSegment> apiSegments,
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
    if (segment.isGap || segment.isCustody) continue;
    if (segment.isFosteringSession || segment.isManual) {
      entries.add(segment);
    }
  }

  entries.sort((a, b) => b.startDate.compareTo(a.startDate));
  return entries;
}
