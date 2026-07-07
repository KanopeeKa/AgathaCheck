import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

/// History and delete actions shown when editing an existing health entry.
class HealthEntryEditActions extends StatelessWidget {
  const HealthEntryEditActions({
    super.key,
    required this.onViewHistory,
    required this.onDelete,
  });

  final VoidCallback onViewHistory;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onViewHistory,
          icon: const Icon(Icons.history),
          label: Text(l.administrationHistory),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('delete_health_entry_button'),
          onPressed: onDelete,
          icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
            side: BorderSide(
              color: theme.colorScheme.error.withValues(alpha: 0.5),
            ),
          ),
          label: Text(l.deleteEntry),
        ),
      ],
    );
  }
}
