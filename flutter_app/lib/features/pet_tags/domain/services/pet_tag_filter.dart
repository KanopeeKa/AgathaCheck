import '../entities/pet_tag.dart';

/// Returns pet ids that satisfy the active tag filter, or `null` when inactive.
Set<String>? matchingPetIdsForTagFilter({
  required Set<String> selectedTagIds,
  required PetTagMatchMode matchMode,
  required List<PetTag> tags,
}) {
  if (selectedTagIds.isEmpty) return null;

  final selectedTags = tags.where((tag) => selectedTagIds.contains(tag.id));
  if (selectedTags.isEmpty) return <String>{};

  if (matchMode == PetTagMatchMode.any) {
    return selectedTags
        .expand((tag) => tag.petIds)
        .toSet();
  }

  final petIdSets = selectedTags.map((tag) => tag.petIds.toSet()).toList();
  if (petIdSets.isEmpty) return <String>{};

  var intersection = petIdSets.first;
  for (var i = 1; i < petIdSets.length; i++) {
    intersection = intersection.intersection(petIdSets[i]);
  }
  return intersection;
}
