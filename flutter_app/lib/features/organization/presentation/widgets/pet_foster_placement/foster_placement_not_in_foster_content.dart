import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// Body content when a pet has no active foster placement.
class FosterPlacementNotInFosterContent extends StatelessWidget {
  const FosterPlacementNotInFosterContent({
    super.key,
    required this.l,
    required this.theme,
    required this.onStart,
    required this.onDirectAdopt,
  });

  final AppLocalizations l;
  final ThemeData theme;
  final VoidCallback onStart;
  final VoidCallback onDirectAdopt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.fosterPlacementNotInFoster,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('start_foster_placement_button'),
          onPressed: onStart,
          icon: const Icon(Icons.home_work_outlined, size: 18),
          label: Text(l.startFosterPlacement),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('direct_adopt_button'),
          onPressed: onDirectAdopt,
          icon: const Icon(Icons.favorite_border, size: 18),
          label: Text(l.directAdopt),
        ),
      ],
    );
  }
}
