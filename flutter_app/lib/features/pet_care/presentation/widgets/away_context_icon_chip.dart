import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';

/// Plum icon chip for Away planning surfaces (dashboard tile, hub cards, empty state).
class AwayContextIconChip extends StatelessWidget {
  const AwayContextIconChip({
    super.key,
    this.icon = Icons.event_busy_outlined,
    this.iconSize = 24,
    this.padding = const EdgeInsets.all(10),
    this.subdued = false,
  });

  final IconData icon;
  final double iconSize;
  final EdgeInsetsGeometry padding;
  final bool subdued;

  @override
  Widget build(BuildContext context) {
    final iconColor = subdued
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : AppColorTokens.awayContextAccent;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: subdued
            ? Theme.of(context).colorScheme.surfaceContainerLow
            : AppColorTokens.awayContextSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: padding,
        child: Icon(icon, size: iconSize, color: iconColor),
      ),
    );
  }
}
