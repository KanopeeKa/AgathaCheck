import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';

class FosteringSessionPreparationChecklist extends StatelessWidget {
  const FosteringSessionPreparationChecklist({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final items = [
      l.fosteringSessionChecklistSupplies,
      l.fosteringSessionChecklistMedical,
      l.fosteringSessionChecklistTransport,
      l.fosteringSessionChecklistHandover,
    ];
    return Card(
      key: const Key('fostering_session_preparation_checklist'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.fosteringSessionPreparationTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              l.fosteringSessionPreparationPlaceholder,
              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, size: 20, color: colorScheme.outline),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
