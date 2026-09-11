import 'package:flutter/material.dart';

import '../../../../../core/utils/calendar_date.dart';
import '../../../../../core/utils/calendar_date_picker.dart';
import '../../../../../l10n/app_localizations.dart';
import '../planned_absence_date_rules.dart';

class PlannedAbsenceDatesStep extends StatelessWidget {
  const PlannedAbsenceDatesStep({
    super.key,
    required this.startsOn,
    required this.endsOn,
    required this.onRangeChanged,
    this.validationMessage,
  });

  final DateTime? startsOn;
  final DateTime? endsOn;
  final void Function(DateTime start, DateTime end) onRangeChanged;
  final String? validationMessage;

  static String formatRangeDisplay(
    AppLocalizations l, {
    required DateTime? startsOn,
    required DateTime? endsOn,
  }) {
    if (startsOn == null || endsOn == null) return '—';
    return l.petTimelineDateRange(
      formatCalendarDateDisplay(startsOn),
      formatCalendarDateDisplay(endsOn),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final today = PlannedAbsenceDateRules.todayCalendar();
    final maxEnd = PlannedAbsenceDateRules.maxEndDate(today);
    final rangeLabel = formatRangeDisplay(
      l,
      startsOn: startsOn,
      endsOn: endsOn,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.careContextAwayDatesStepTitle,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          l.careContextAwayDatesStepBody,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Semantics(
          button: true,
          label: l.careContextAwayDatesRangeLabel,
          value: rangeLabel,
          child: OutlinedButton(
            key: const Key('planned_absence_date_range'),
            onPressed: () async {
              final picked = await showCalendarDateRangePicker(
                context: context,
                rangeStart: startsOn,
                rangeEnd: endsOn,
                firstDate: today,
                lastDate: maxEnd,
                helpText: l.careContextAwayDatesRangeLabel,
              );
              if (picked == null) return;
              onRangeChanged(picked.start, picked.end);
            },
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              minimumSize: const Size.fromHeight(56),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.careContextAwayDatesRangeLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(rangeLabel, style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
                const Icon(Icons.date_range_outlined),
              ],
            ),
          ),
        ),
        if (validationMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            validationMessage!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
