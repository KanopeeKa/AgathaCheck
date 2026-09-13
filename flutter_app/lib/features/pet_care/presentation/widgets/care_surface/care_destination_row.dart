import 'package:flutter/material.dart';

import 'care_surface_tokens.dart';

/// Destination role — minimal navigation row (label + chevron, no card chrome).
class CareDestinationRow extends StatelessWidget {
  const CareDestinationRow({
    super.key,
    required this.label,
    required this.semanticLabel,
    required this.onTap,
    this.trailingDetail,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onTap;
  final String? trailingDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: semanticLabel,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: CareSurfaceTokens.destinationPadding,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (trailingDetail != null) ...[
                Text(
                  trailingDetail!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
