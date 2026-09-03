import 'collection_filter_models.dart';

/// Pure helpers for collection filter selection state.
class CollectionFilterController {
  const CollectionFilterController._();

  static int activeChoiceCount(CollectionFilterSelections selections) {
    var count = 0;
    for (final values in selections.values) {
      count += values.length;
    }
    return count;
  }

  static List<ActiveFilterChipSpec> activeChips({
    required List<CollectionFilterDimension> dimensions,
    required CollectionFilterSelections selections,
  }) {
    final chips = <ActiveFilterChipSpec>[];
    for (final dimension in dimensions) {
      final selected = selections[dimension.id] ?? const {};
      for (final choiceId in selected) {
        final choice = dimension.choiceById(choiceId);
        if (choice == null || choice.isDefault) continue;
        chips.add(
          ActiveFilterChipSpec(
            dimensionId: dimension.id,
            choiceId: choiceId,
            label: choice.label,
          ),
        );
      }
    }
    return chips;
  }

  static int activeCountForDimension(
    CollectionFilterDimension dimension,
    CollectionFilterSelections selections,
  ) {
    final selected = selections[dimension.id] ?? const {};
    return selected.where((id) {
      final choice = dimension.choiceById(id);
      return choice != null && !choice.isDefault;
    }).length;
  }

  static bool isChoiceSelected(
    CollectionFilterDimension dimension,
    CollectionFilterSelections selections,
    String choiceId,
  ) {
    final choice = dimension.choiceById(choiceId);
    if (choice == null) return false;
    if (choice.isDefault) {
      return (selections[dimension.id] ?? const {}).isEmpty;
    }
    return (selections[dimension.id] ?? const {}).contains(choiceId);
  }

  static CollectionFilterSelections toggleChoice({
    required CollectionFilterDimension dimension,
    required CollectionFilterSelections selections,
    required String choiceId,
    required bool selected,
  }) {
    final choice = dimension.choiceById(choiceId);
    if (choice == null) return selections;

    final next = Map<String, Set<String>>.from(selections);
    final current = Set<String>.from(next[dimension.id] ?? const {});

    if (choice.isDefault) {
      next[dimension.id] = {};
      return next;
    }

    if (dimension.multiSelect) {
      if (selected) {
        current.add(choiceId);
      } else {
        current.remove(choiceId);
      }
      next[dimension.id] = current;
      return next;
    }

    next[dimension.id] = selected ? {choiceId} : {};
    return next;
  }

  static CollectionFilterSelections removeActiveChip({
    required CollectionFilterSelections selections,
    required ActiveFilterChipSpec chip,
  }) {
    final next = Map<String, Set<String>>.from(selections);
    final current = Set<String>.from(next[chip.dimensionId] ?? const {});
    current.remove(chip.choiceId);
    next[chip.dimensionId] = current;
    return next;
  }

  static CollectionFilterSelections clearDimension(
    CollectionFilterSelections selections,
    String dimensionId,
  ) {
    final next = Map<String, Set<String>>.from(selections);
    next[dimensionId] = {};
    return next;
  }

  static CollectionFilterSelections clearAll(
    CollectionFilterSelections selections,
  ) {
    return {for (final entry in selections.entries) entry.key: <String>{}};
  }
}
