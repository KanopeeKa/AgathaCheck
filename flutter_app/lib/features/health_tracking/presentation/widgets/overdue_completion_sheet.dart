import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/calendar_date.dart';
import '../../../../core/utils/calendar_date_picker.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/health_occurrence.dart';

/// Overdue completion: today, scheduled date, or custom (D-CIE-009).
Future<DateTime?> showOverdueCompletionSheet(
  BuildContext context, {
  required HealthOccurrence occurrence,
  required DateTime now,
}) {
  final l = AppLocalizations.of(context)!;
  final today = calendarDateOnly(now);
  final scheduled = calendarDateOnly(occurrence.scheduledDate);
  final scheduledLabel = DateFormat.yMMMd().format(scheduled);

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.careWhenWasThisDoneTitle,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('overdue_completion_today'),
                onPressed: () => Navigator.pop(ctx, today),
                child: Text(l.careCompletedToday),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('overdue_completion_scheduled'),
                onPressed: () => Navigator.pop(ctx, scheduled),
                child: Text(l.careCompletedOnScheduledDate(scheduledLabel)),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const Key('overdue_completion_choose'),
                onPressed: () async {
                  final picked = await showCalendarDatePicker(
                    context: ctx,
                    initialDate: scheduled.isAfter(today) ? today : scheduled,
                    firstDate: DateTime(2000),
                    lastDate: today,
                  );
                  if (picked != null && ctx.mounted) {
                    Navigator.pop(ctx, picked);
                  }
                },
                child: Text(l.careChooseCompletionDate),
              ),
            ],
          ),
        ),
      );
    },
  );
}
