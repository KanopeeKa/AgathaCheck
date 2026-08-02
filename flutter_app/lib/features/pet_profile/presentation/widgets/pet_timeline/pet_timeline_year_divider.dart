import 'package:flutter/material.dart';

/// Subtle year separator between timeline event groups (newest-first order).
class PetTimelineYearDivider extends StatelessWidget {
  const PetTimelineYearDivider({super.key, required this.year});

  final String year;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
      letterSpacing: 0.4,
    );
    final lineColor = colorScheme.outlineVariant.withValues(alpha: 0.45);

    return Padding(
      key: Key('pet_timeline_year_$year'),
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
      child: Row(
        children: [
          Expanded(child: Divider(height: 1, thickness: 1, color: lineColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(year, style: labelStyle),
          ),
          Expanded(child: Divider(height: 1, thickness: 1, color: lineColor)),
        ],
      ),
    );
  }
}
