import 'package:flutter/material.dart';

import '../../../../../core/utils/calendar_date.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/away_plan_readiness.dart';
import '../../domain/entities/planned_absence.dart';
import '../away_plan_copy.dart';

class AwayPlanHeaderSection extends StatelessWidget {
  const AwayPlanHeaderSection({
    super.key,
    required this.absence,
    required this.readiness,
  });

  final PlannedAbsence absence;
  final AwayPlanReadiness readiness;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final start = parseCalendarDate(absence.startsOn);
    final end = parseCalendarDate(absence.endsOn);
    final dateRange = start != null && end != null
        ? l.careContextAwayPreviewDateRange(
            formatCalendarDateDisplay(start),
            formatCalendarDateDisplay(end),
          )
        : '${absence.startsOn} – ${absence.endsOn}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(dateRange, style: theme.textTheme.headlineSmall),
        if (absence.isCancelled) ...[
          const SizedBox(height: 8),
          Text(
            l.careContextAwayPlanStatusCancelled,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          l.careContextAwayPlanCarerCoverageTitle,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          AwayPlanCopy.carerCoverageSummary(l, readiness.carerCoverage),
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        Text(
          l.careContextAwayPlanCareCoverageTitle,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          AwayPlanCopy.careCoverageSummary(l, readiness.careCoverage),
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
}
