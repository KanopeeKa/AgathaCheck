import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

class PetListBulkShareBar extends StatelessWidget {
  const PetListBulkShareBar({
    super.key,
    required this.bulkShareMode,
    required this.l,
    required this.onToggle,
    required this.onAction,
  });

  final bool bulkShareMode;
  final AppLocalizations l;
  final VoidCallback onToggle;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              bulkShareMode ? l.bulkShareSelectHint : l.allPets,
              style: theme.textTheme.titleMedium,
            ),
          ),
          TextButton(
            key: const Key('bulk_share_toggle'),
            onPressed: onToggle,
            child: Text(bulkShareMode ? l.cancel : l.bulkShare),
          ),
          if (bulkShareMode)
            FilledButton(
              key: const Key('bulk_share_action'),
              onPressed: onAction,
              child: Text(l.bulkShareAction),
            ),
        ],
      ),
    );
  }
}
