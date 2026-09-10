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
    required this.onStartsOnChanged,
    required this.onEndsOnChanged,
    this.validationMessage,
  });

  final DateTime? startsOn;
  final DateTime? endsOn;
  final ValueChanged<DateTime?> onStartsOnChanged;
  final ValueChanged<DateTime?> onEndsOnChanged;
  final String? validationMessage;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final today = PlannedAbsenceDateRules.todayCalendar();
    final maxEnd = PlannedAbsenceDateRules.maxEndDate(today);

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
        _DateField(
          key: const Key('planned_absence_starts_on'),
          label: l.careContextAwayStartsOnLabel,
          date: startsOn,
          onPick: () async {
            final picked = await showCalendarDatePicker(
              context: context,
              initialDate: startsOn ?? today,
              firstDate: today,
              lastDate: maxEnd,
              helpText: l.careContextAwayStartsOnLabel,
            );
            if (picked != null) onStartsOnChanged(picked);
          },
        ),
        const SizedBox(height: 12),
        _DateField(
          key: const Key('planned_absence_ends_on'),
          label: l.careContextAwayEndsOnLabel,
          date: endsOn,
          onPick: () async {
            final picked = await showCalendarDatePicker(
              context: context,
              initialDate: endsOn ?? startsOn ?? today,
              firstDate: startsOn ?? today,
              lastDate: maxEnd,
              helpText: l.careContextAwayEndsOnLabel,
            );
            if (picked != null) onEndsOnChanged(picked);
          },
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

class _DateField extends StatelessWidget {
  const _DateField({
    super.key,
    required this.label,
    required this.date,
    required this.onPick,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = date == null ? '—' : formatCalendarDateDisplay(date!);

    return Semantics(
      button: true,
      label: label,
      value: value,
      child: OutlinedButton(
        onPressed: onPick,
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
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(value, style: theme.textTheme.titleMedium),
                ],
              ),
            ),
            const Icon(Icons.calendar_today_outlined),
          ],
        ),
      ),
    );
  }
}
