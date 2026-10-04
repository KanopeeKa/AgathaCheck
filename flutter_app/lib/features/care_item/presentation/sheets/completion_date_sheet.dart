import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/calendar_date_picker.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/care_occurrence.dart';

/// "When was this done?" (DN-3): Today first, the due date, or another date
/// up to today. The only completion sheet (§18.6.6).
Future<DateTime?> showCompletionDateSheet(
  BuildContext context, {
  required OpenOccurrence occurrence,
  required CareAsOf asOf,
}) {
  final l = AppLocalizations.of(context)!;
  final today = asOf.date;
  final due = occurrence.date;
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        key: const Key('completion_date_sheet'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l.careWhenWasThisDoneTitle,
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('completion_date_today'),
              onPressed: () => Navigator.pop(ctx, today),
              child: Text(l.careCompletedToday),
            ),
            if (due.isBefore(today)) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                key: const Key('completion_date_due'),
                onPressed: () => Navigator.pop(ctx, due),
                child: Text(
                  l.careCompletedOnScheduledDate(
                    DateFormat.yMMMd().format(due),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              key: const Key('completion_date_other'),
              onPressed: () async {
                final picked = await showCalendarDatePicker(
                  context: ctx,
                  initialDate: due.isAfter(today) ? today : due,
                  firstDate: DateTime(2000),
                  lastDate: today,
                );
                if (picked != null && ctx.mounted) Navigator.pop(ctx, picked);
              },
              child: Text(l.careChooseCompletionDate),
            ),
          ],
        ),
      ),
    ),
  );
}
