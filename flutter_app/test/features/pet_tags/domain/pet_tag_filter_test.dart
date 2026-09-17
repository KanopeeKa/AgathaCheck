import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/features/pet_tags/domain/entities/pet_tag.dart';
import 'package:pet_profile_app/features/pet_tags/domain/services/pet_tag_filter.dart';

void main() {
  const tags = [
    PetTag(id: 't1', name: 'A', petIds: ['p1', 'p2']),
    PetTag(id: 't2', name: 'B', petIds: ['p2', 'p3']),
  ];

  test('returns null when no tags selected', () {
    expect(
      matchingPetIdsForTagFilter(
        selectedTagIds: {},
        matchMode: PetTagMatchMode.any,
        tags: tags,
      ),
      isNull,
    );
  });

  test('match any returns union of pet ids', () {
    expect(
      matchingPetIdsForTagFilter(
        selectedTagIds: {'t1', 't2'},
        matchMode: PetTagMatchMode.any,
        tags: tags,
      ),
      {'p1', 'p2', 'p3'},
    );
  });

  test('match all returns intersection of pet ids', () {
    expect(
      matchingPetIdsForTagFilter(
        selectedTagIds: {'t1', 't2'},
        matchMode: PetTagMatchMode.all,
        tags: tags,
      ),
      {'p2'},
    );
  });
}
