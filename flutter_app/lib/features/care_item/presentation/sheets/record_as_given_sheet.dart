import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/calendar_date_picker.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/occurrence_detail.dart';

/// Date picker for recording a closed Not recorded dose as done (FR-3, AC-C3).
Future<DateTime?> showRecordAsGivenSheet(
  BuildContext context, {
  required CareOccurrence occurrence,
  required DateTime today,
}) {
  final l = AppLocalizations.of(context)!;
  var selected = occurrence.completedOn ?? occurrence.date;
  if (selected.isAfter(today)) selected = today;

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              key: const Key('record_as_given_sheet'),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      l.careRecordAsDone,
                      style: Theme.of(ctx).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.careRecordAsGivenHint,
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    key: const Key('record_as_given_date'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.careCompletedOnLabel),
                    subtitle: Text(DateFormat.yMMMd().format(selected)),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: () async {
                      final picked = await showCalendarDatePicker(
                        context: ctx,
                        initialDate: selected,
                        firstDate: occurrence.date,
                        lastDate: today,
                      );
                      if (picked != null) setState(() => selected = picked);
                    },
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const Key('record_as_given_confirm'),
                    onPressed: () => Navigator.pop(ctx, selected),
                    child: Text(l.careRecordAsDone),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}
