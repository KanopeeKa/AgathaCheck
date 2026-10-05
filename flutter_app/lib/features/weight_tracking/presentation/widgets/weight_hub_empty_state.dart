import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

class WeightHubEmptyState extends StatelessWidget {
  const WeightHubEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l = AppLocalizations.of(context)!;

    return MergeSemantics(
      child: Semantics(
        label: l.noWeightDataYet,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.scale_outlined, size: 48, color: colorScheme.outline),
              const SizedBox(height: 8),
              Text(
                l.noWeightDataYet,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l.tapAddEntryToStart,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WeightHubAddFooterButton extends StatelessWidget {
  const WeightHubAddFooterButton({
    required this.onPressed,
    required this.label,
    super.key,
  });

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: FilledButton.tonalIcon(
        key: const Key('weight_tracking_add_footer'),
        onPressed: onPressed,
        icon: const Icon(Icons.add, size: 18),
        label: Text(label),
      ),
    );
  }
}
