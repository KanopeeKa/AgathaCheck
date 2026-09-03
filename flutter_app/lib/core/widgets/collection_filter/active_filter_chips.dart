import 'package:flutter/material.dart';

import 'collection_filter_models.dart';

/// Removable chips summarising non-default active filter selections.
class ActiveFilterChipsRow extends StatelessWidget {
  const ActiveFilterChipsRow({
    super.key,
    required this.chips,
    required this.onRemove,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 8),
  });

  final List<ActiveFilterChipSpec> chips;
  final ValueChanged<ActiveFilterChipSpec> onRemove;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          for (final chip in chips)
            InputChip(
              key: Key('active_filter_${chip.dimensionId}_${chip.choiceId}'),
              label: Text(chip.label),
              onDeleted: () => onRemove(chip),
              deleteIcon: const Icon(Icons.close, size: 18),
            ),
        ],
      ),
    );
  }
}
