import 'package:flutter_test/flutter_test.dart';
import 'package:pet_profile_app/core/widgets/collection_filter/collection_filter_controller.dart';
import 'package:pet_profile_app/core/widgets/collection_filter/collection_filter_models.dart';

void main() {
  const typeDimension = CollectionFilterDimension(
    id: 'type',
    label: 'Type',
    choices: [
      CollectionFilterChoice(id: 'all', label: 'All', isDefault: true),
      CollectionFilterChoice(id: 'med', label: 'Medication'),
      CollectionFilterChoice(id: 'prev', label: 'Preventive'),
    ],
  );

  test('empty selections mean all for default choice', () {
    expect(
      CollectionFilterController.isChoiceSelected(typeDimension, {}, 'all'),
      isTrue,
    );
    expect(
      CollectionFilterController.isChoiceSelected(typeDimension, {}, 'med'),
      isFalse,
    );
  });

  test('multi-select OR toggles independent choices', () {
    var selections = CollectionFilterController.toggleChoice(
      dimension: typeDimension,
      selections: const {},
      choiceId: 'med',
      selected: true,
    );
    selections = CollectionFilterController.toggleChoice(
      dimension: typeDimension,
      selections: selections,
      choiceId: 'prev',
      selected: true,
    );

    expect(selections['type'], {'med', 'prev'});
    expect(
      CollectionFilterController.activeChoiceCount(selections),
      2,
    );
  });

  test('selecting default clears dimension', () {
    final selections = CollectionFilterController.toggleChoice(
      dimension: typeDimension,
      selections: const {'type': {'med'}},
      choiceId: 'all',
      selected: true,
    );

    expect(selections['type'], isEmpty);
  });

  test('active chips skip default choices', () {
    final selections = const {'type': {'med', 'prev'}};
    final chips = CollectionFilterController.activeChips(
      dimensions: [typeDimension],
      selections: selections,
    );

    expect(chips, hasLength(2));
    expect(chips.map((c) => c.label), ['Medication', 'Preventive']);
  });

  test('removeActiveChip removes one choice', () {
    const selections = {'type': {'med', 'prev'}};
    final chips = CollectionFilterController.activeChips(
      dimensions: [typeDimension],
      selections: selections,
    );
    final next = CollectionFilterController.removeActiveChip(
      selections: selections,
      chip: chips.first,
    );

    expect(next['type'], {'prev'});
  });

  test('clearAll empties every dimension', () {
    final next = CollectionFilterController.clearAll(const {
      'type': {'med'},
      'status': {'open'},
    });

    expect(next['type'], isEmpty);
    expect(next['status'], isEmpty);
  });
}
