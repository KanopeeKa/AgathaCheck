import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import 'active_filter_chips.dart';
import 'collection_filter_controller.dart';
import 'collection_filter_models.dart';
import 'collection_filter_sheet.dart';
import 'collection_filter_toolbar.dart';

/// Responsive collection filter bar: toolbar on wide viewports, sheet on narrow.
class CollectionFilterBar extends StatelessWidget {
  const CollectionFilterBar({
    super.key,
    required this.dimensions,
    required this.selections,
    required this.onSelectionsChanged,
    required this.primaryDimensionIds,
    this.moreDimensionIds = const [],
    this.mobileBreakpoint = 600,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 8),
  });

  final List<CollectionFilterDimension> dimensions;
  final CollectionFilterSelections selections;
  final ValueChanged<CollectionFilterSelections> onSelectionsChanged;
  final List<String> primaryDimensionIds;
  final List<String> moreDimensionIds;
  final double mobileBreakpoint;
  final EdgeInsetsGeometry padding;

  void _clearAll() {
    onSelectionsChanged(CollectionFilterController.clearAll(selections));
  }

  void _removeChip(ActiveFilterChipSpec chip) {
    onSelectionsChanged(
      CollectionFilterController.removeActiveChip(
        selections: selections,
        chip: chip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final activeCount = CollectionFilterController.activeChoiceCount(
      selections,
    );
    final activeChips = CollectionFilterController.activeChips(
      dimensions: dimensions,
      selections: selections,
    );

    final controls = width < mobileBreakpoint
        ? _MobileFilterControls(
            activeCount: activeCount,
            label: activeCount > 0
                ? l.collectionFiltersWithCount(activeCount)
                : l.orgPetsFiltersLabel,
            onOpenSheet: () => CollectionFilterSheet.show(
              context: context,
              dimensions: dimensions,
              selections: selections,
              onSelectionsChanged: onSelectionsChanged,
              onClearAll: _clearAll,
            ),
          )
        : CollectionFilterToolbar(
            dimensions: dimensions,
            selections: selections,
            onSelectionsChanged: onSelectionsChanged,
            primaryDimensionIds: primaryDimensionIds,
            moreDimensionIds: moreDimensionIds,
            padding: EdgeInsets.zero,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(padding: padding, child: controls),
        ActiveFilterChipsRow(
          chips: activeChips,
          onRemove: _removeChip,
          padding: padding,
        ),
      ],
    );
  }
}

class _MobileFilterControls extends StatelessWidget {
  const _MobileFilterControls({
    required this.activeCount,
    required this.label,
    required this.onOpenSheet,
  });

  final int activeCount;
  final String label;
  final VoidCallback onOpenSheet;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        button: true,
        label: label,
        child: OutlinedButton.icon(
          key: const Key('collection_filter_mobile_trigger'),
          onPressed: onOpenSheet,
          style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
          icon: const Icon(Icons.filter_list, size: 20),
          label: Text(label),
        ),
      ),
    );
  }
}
