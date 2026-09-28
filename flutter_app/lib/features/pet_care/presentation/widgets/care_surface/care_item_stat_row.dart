import 'package:flutter/material.dart';

import 'care_surface_tokens.dart';

/// Horizontal stat grid (Frequency · Schedule type · Reminder).
class CareItemStatRow extends StatelessWidget {
  const CareItemStatRow({super.key, required this.cells});

  final List<CareItemStatCellData> cells;

  @override
  Widget build(BuildContext context) {
    if (cells.isEmpty) return const SizedBox.shrink();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cells.length; i++) ...[
            if (i > 0)
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: CareSurfaceTokens.moduleBorder(),
              ),
            Expanded(child: CareItemStatCell(data: cells[i])),
          ],
        ],
      ),
    );
  }
}

class CareItemStatCellData {
  const CareItemStatCellData({
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;
}

class CareItemStatCell extends StatelessWidget {
  const CareItemStatCell({super.key, required this.data});

  final CareItemStatCellData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.icon != null) ...[
            Icon(data.icon, size: 18, color: colorScheme.primary),
            const SizedBox(height: 4),
          ],
          Text(
            data.label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
