import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'collection_filter_controller.dart';
import 'collection_filter_models.dart';

/// Toolbar control that opens a menu of checkbox (multi) or radio (single) choices.
class FilterDimensionMenuButton extends StatelessWidget {
  const FilterDimensionMenuButton({
    super.key,
    required this.dimension,
    required this.selections,
    required this.onSelectionsChanged,
  });

  final CollectionFilterDimension dimension;
  final CollectionFilterSelections selections;
  final ValueChanged<CollectionFilterSelections> onSelectionsChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final activeCount = CollectionFilterController.activeCountForDimension(
      dimension,
      selections,
    );
    final label = activeCount > 0
        ? '${dimension.label} ($activeCount)'
        : dimension.label;

    return MenuAnchor(
      key: Key('filter_dimension_menu_${dimension.id}'),
      menuChildren: [
        for (final choice in dimension.choices)
          _DimensionMenuItem(
            dimension: dimension,
            choice: choice,
            selections: selections,
            onSelectionsChanged: onSelectionsChanged,
          ),
        if (activeCount > 0) ...[
          const Divider(height: 1),
          MenuItemButton(
            key: Key('filter_dimension_clear_${dimension.id}'),
            onPressed: () {
              onSelectionsChanged(
                CollectionFilterController.clearDimension(
                  selections,
                  dimension.id,
                ),
              );
            },
            child: Text(l.clear),
          ),
        ],
      ],
      builder: (context, controller, child) {
        return Semantics(
          button: true,
          label: dimension.label,
          child: OutlinedButton(
            key: Key('filter_dimension_trigger_${dimension.id}'),
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              visualDensity: VisualDensity.compact,
            ),
            child: Text(label),
          ),
        );
      },
    );
  }
}

class _DimensionMenuItem extends StatelessWidget {
  const _DimensionMenuItem({
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
        key: Key('filter_choice_${dimension.id}_${choice.id}'),
        value: selected,
        title: Text(choice.label),
        controlAffinity: ListTileControlAffinity.leading,
        dense: true,
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
      key: Key('filter_choice_${dimension.id}_${choice.id}'),
      value: selected,
      title: Text(choice.label),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
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
