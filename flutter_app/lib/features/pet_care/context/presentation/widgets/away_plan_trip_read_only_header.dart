import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/shell_return_navigation.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/planned_absence.dart';
import '../planned_absence_display.dart';

/// Read-only trip summary on a pet away plan screen with [See absence].
class AwayPlanTripReadOnlyHeader extends StatelessWidget {
  const AwayPlanTripReadOnlyHeader({super.key, required this.absence});

  final PlannedAbsence absence;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = PlannedAbsenceDisplay.primaryLabel(l, absence);
    final secondaryDates = PlannedAbsenceDisplay.secondaryDateLine(l, absence);
    final traveller = PlannedAbsenceDisplay.travellerLine(l, absence);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 8),
            Text(traveller, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                identifier: 'away_plan_see_absence',
                button: true,
                label: l.careContextSeeAbsence,
                child: TextButton(
                  key: const Key('away_plan_see_absence'),
                  onPressed: () {
                    final returnTo = currentShellLocation(context);
                    context.push(
                      awayPlanDetailLocation(absence.id, returnTo: returnTo),
                    );
                  },
                  child: Text(l.careContextSeeAbsence),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
