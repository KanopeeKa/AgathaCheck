import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'collection_filter_controller.dart';
import 'collection_filter_models.dart';
import 'filter_dimension_menu.dart';

/// Compact desktop/tablet filter toolbar with primary dimensions and overflow.
class CollectionFilterToolbar extends StatelessWidget {
  const CollectionFilterToolbar({
    super.key,
    required this.dimensions,
    required this.selections,
    required this.onSelectionsChanged,
    required this.primaryDimensionIds,
    required this.moreDimensionIds,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 8),
  });

  final List<CollectionFilterDimension> dimensions;
  final CollectionFilterSelections selections;
  final ValueChanged<CollectionFilterSelections> onSelectionsChanged;
  final List<String> primaryDimensionIds;
  final List<String> moreDimensionIds;
  final EdgeInsetsGeometry padding;

  CollectionFilterDimension? _dimension(String id) {
    for (final dimension in dimensions) {
      if (dimension.id == id) return dimension;
    }
    return null;
  }

  Iterable<CollectionFilterDimension> get _moreDimensions sync* {
    for (final id in moreDimensionIds) {
      final dimension = _dimension(id);
      if (dimension != null) yield dimension;
    }
  }

  int get _moreActiveCount {
    var count = 0;
    for (final dimension in _moreDimensions) {
      count += CollectionFilterController.activeCountForDimension(
        dimension,
        selections,
      );
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final moreDimensions = _moreDimensions.toList();
    final moreLabel = _moreActiveCount > 0
        ? '${l.collectionFilterMore} ($_moreActiveCount)'
        : l.collectionFilterMore;

    return Padding(
      padding: padding,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final id in primaryDimensionIds)
            if (_dimension(id) case final dimension?)
              FilterDimensionMenuButton(
                dimension: dimension,
                selections: selections,
                onSelectionsChanged: onSelectionsChanged,
              ),
          if (moreDimensions.isNotEmpty)
            MenuAnchor(
              key: const Key('collection_filter_more_menu'),
              menuChildren: [
                for (final dimension in moreDimensions)
                  _MoreDimensionSection(
                    dimension: dimension,
                    selections: selections,
                    onSelectionsChanged: onSelectionsChanged,
                  ),
              ],
              builder: (context, controller, child) {
                return Semantics(
                  button: true,
                  label: l.collectionFilterMore,
                  child: OutlinedButton(
                    key: const Key('collection_filter_more_trigger'),
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
                    child: Text(moreLabel),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _MoreDimensionSection extends StatelessWidget {
  const _MoreDimensionSection({
    required this.dimension,
    required this.selections,
    required this.onSelectionsChanged,
  });

  final CollectionFilterDimension dimension;
  final CollectionFilterSelections selections;
  final ValueChanged<CollectionFilterSelections> onSelectionsChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            dimension.label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        for (final choice in dimension.choices)
          _MoreChoiceTile(
            dimension: dimension,
            choice: choice,
            selections: selections,
            onSelectionsChanged: onSelectionsChanged,
          ),
      ],
    );
  }
}

class _MoreChoiceTile extends StatelessWidget {
  const _MoreChoiceTile({
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
        key: Key('filter_more_${dimension.id}_${choice.id}'),
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
      key: Key('filter_more_${dimension.id}_${choice.id}'),
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
