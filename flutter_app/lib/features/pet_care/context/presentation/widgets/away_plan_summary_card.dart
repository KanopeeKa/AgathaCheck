import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/planned_absence.dart';
import '../planned_absence_display.dart';

class AwayPlanSummaryCard extends StatelessWidget {
  const AwayPlanSummaryCard({
    super.key,
    required this.absence,
    required this.onEdit,
  });

  final PlannedAbsence absence;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = PlannedAbsenceDisplay.primaryLabel(l, absence);
    final secondaryDates = PlannedAbsenceDisplay.secondaryDateLine(l, absence);
    final note = absence.handoverNote?.trim();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(primary, style: theme.textTheme.titleMedium),
                  if (secondaryDates != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      secondaryDates,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (absence.isCancelled) ...[
                    const SizedBox(height: 8),
                    Text(
                      l.careContextAwayPlanStatusCancelled,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                  if (note != null && note.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      l.pdfNotesLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      note,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
            if (onEdit != null)
              TextButton(
                key: const Key('away_plan_summary_edit'),
                onPressed: onEdit,
                child: Text(l.careContextAwaySummaryEdit),
              ),
          ],
        ),
      ),
    );
  }
}
