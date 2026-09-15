import 'package:flutter/material.dart';

import '../../../../../core/utils/calendar_date.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../domain/entities/planned_absence.dart';

class AwayPlanDetailsSection extends StatelessWidget {
  const AwayPlanDetailsSection({
    super.key,
    required this.absence,
    required this.petNamesById,
  });

  final PlannedAbsence absence;
  final Map<String, String> petNamesById;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final start = parseCalendarDate(absence.startsOn);
    final end = parseCalendarDate(absence.endsOn);
    final dateLabel = start != null && end != null
        ? l.careContextAwayPreviewDateRange(
            formatCalendarDateDisplay(start),
            formatCalendarDateDisplay(end),
          )
        : '${absence.startsOn} – ${absence.endsOn}';
    final petNames = [...absence.petIds]
        .map((petId) => petNamesById[petId] ?? petId)
        .toList()
      ..sort();
    final statusLabel = absence.isCancelled
        ? l.careContextAwayPlanStatusCancelled
        : l.careContextAwayPlanStatusActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.careContextAwayPlanDetailsTitle,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DetailRow(
                  label: l.careContextAwayPlanDatesLabel,
                  value: dateLabel,
                ),
                const SizedBox(height: 12),
                _DetailRow(
                  label: l.careContextAwayPlanPetsLabel,
                  value: petNames.join(', '),
                ),
                const SizedBox(height: 12),
                _DetailRow(label: l.careContextAwayPlanStatusLabel, value: statusLabel),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.bodyLarge),
      ],
    );
  }
}
