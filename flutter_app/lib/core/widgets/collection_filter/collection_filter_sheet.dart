import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'collection_filter_controller.dart';
import 'collection_filter_models.dart';

/// Mobile bottom sheet listing all filter dimensions and choices.
class CollectionFilterSheet extends StatelessWidget {
  const CollectionFilterSheet({
    super.key,
    required this.dimensions,
    required this.selections,
    required this.onSelectionsChanged,
    required this.onClearAll,
  });

  final List<CollectionFilterDimension> dimensions;
  final CollectionFilterSelections selections;
  final ValueChanged<CollectionFilterSelections> onSelectionsChanged;
  final VoidCallback onClearAll;

  static Future<void> show({
    required BuildContext context,
    required List<CollectionFilterDimension> dimensions,
    required CollectionFilterSelections selections,
    required ValueChanged<CollectionFilterSelections> onSelectionsChanged,
    required VoidCallback onClearAll,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => CollectionFilterSheet(
        dimensions: dimensions,
        selections: selections,
        onSelectionsChanged: onSelectionsChanged,
        onClearAll: onClearAll,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final activeCount = CollectionFilterController.activeChoiceCount(selections);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      activeCount > 0
                          ? l.collectionFiltersWithCount(activeCount)
                          : l.orgPetsFiltersLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (activeCount > 0)
                    TextButton(
                      key: const Key('collection_filter_clear_all'),
                      onPressed: onClearAll,
                      child: Text(l.collectionFilterClearAll),
                    ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final dimension in dimensions) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                        child: Text(
                          dimension.label,
                          style: theme.textTheme.labelMedium,
                        ),
                      ),
                      for (final choice in dimension.choices)
                        _SheetChoiceTile(
                          dimension: dimension,
                          choice: choice,
                          selections: selections,
                          onSelectionsChanged: onSelectionsChanged,
                        ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                key: const Key('collection_filter_sheet_done'),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.done),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetChoiceTile extends StatelessWidget {
  const _SheetChoiceTile({
    required this.dimension,
    required this.choice,
    required this.selections,
    required this.onSelectionsChanged,
  });

  final CollectionFilterDimension dimension;
  final CollectionFilterChoice choice;
  final CollectionFilterSelections selections;
  final ValueChanged<CollectionFilterSelections> onSelectionsChanged;

  @override
  Widget build(BuildContext context) {
    final selected = CollectionFilterController.isChoiceSelected(
      dimension,
      selections,
      choice.id,
    );

    if (dimension.multiSelect) {
      return CheckboxListTile(
        key: Key('filter_sheet_${dimension.id}_${choice.id}'),
        value: selected,
        title: Text(choice.label),
        controlAffinity: ListTileControlAffinity.leading,
        onChanged: (value) {
          onSelectionsChanged(
            CollectionFilterController.toggleChoice(
              dimension: dimension,
              selections: selections,
              choiceId: choice.id,
              selected: value ?? false,
            ),
          );
        },
      );
    }

    return CheckboxListTile(
      key: Key('filter_sheet_${dimension.id}_${choice.id}'),
      value: selected,
      title: Text(choice.label),
      controlAffinity: ListTileControlAffinity.leading,
      onChanged: (_) {
        onSelectionsChanged(
          CollectionFilterController.toggleChoice(
            dimension: dimension,
            selections: selections,
            choiceId: choice.id,
            selected: true,
          ),
        );
      },
    );
  }
}
