/// Models for the canonical collection-filter pattern.
///
/// See `docs/design/collection-filter.md`.

/// One selectable value within a filter dimension.
class CollectionFilterChoice {
  const CollectionFilterChoice({
    required this.id,
    required this.label,
    this.isDefault = false,
  });

  final String id;
  final String label;

  /// When true, selecting this choice clears the dimension (same as "all").
  final bool isDefault;
}

/// A named group of filter options (Pet, Type, Status, …).
class CollectionFilterDimension {
  const CollectionFilterDimension({
    required this.id,
    required this.label,
    required this.choices,
    this.multiSelect = true,
  });

  final String id;
  final String label;
  final List<CollectionFilterChoice> choices;

  /// When false, choosing a value replaces any prior selection in the dimension.
  final bool multiSelect;

  CollectionFilterChoice? choiceById(String choiceId) {
    for (final choice in choices) {
      if (choice.id == choiceId) return choice;
    }
    return null;
  }
}

/// Dimension id → selected choice ids. Empty set means no filter (all values).
typedef CollectionFilterSelections = Map<String, Set<String>>;

/// A removable active-filter chip derived from [CollectionFilterSelections].
class ActiveFilterChipSpec {
  const ActiveFilterChipSpec({
    required this.dimensionId,
    required this.choiceId,
    required this.label,
  });

  final String dimensionId;
  final String choiceId;
  final String label;
}
