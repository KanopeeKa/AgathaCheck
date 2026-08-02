import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/pet_timeline_segment.dart';
import 'pet_timeline_labels.dart';

/// Circular node on the timeline spine with a kind-specific icon.
class PetTimelineNode extends StatelessWidget {
  const PetTimelineNode({
    super.key,
    required this.icon,
    required this.semanticsLabel,
    required this.showConnectorBelow,
  });

  final IconData icon;
  final String semanticsLabel;
  final bool showConnectorBelow;

  static const double nodeSize = 40;
  static const double spineWidth = 48;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: spineWidth,
      child: Column(
        children: [
          Semantics(
            container: true,
            label: semanticsLabel,
            child: Container(
              width: nodeSize,
              height: nodeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceContainerHighest,
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
              child: Icon(icon, size: 20, color: colorScheme.primary),
            ),
          ),
          if (showConnectorBelow)
            Expanded(
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  key: const Key('pet_timeline_node_connector'),
                  width: 2,
                  color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One timeline row: spine node + entry card.
class PetTimelineEventRow extends StatelessWidget {
  const PetTimelineEventRow({
    super.key,
    required this.segment,
    required this.showConnectorBelow,
    required this.child,
  });

  final PetTimelineSegment segment;
  final bool showConnectorBelow;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PetTimelineNode(
            icon: petTimelineIcon(segment),
            semanticsLabel: petTimelineHeadline(segment, l),
            showConnectorBelow: showConnectorBelow,
          ),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}
