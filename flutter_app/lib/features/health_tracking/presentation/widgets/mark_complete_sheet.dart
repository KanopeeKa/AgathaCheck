import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/calendar_date.dart';

/// Bottom sheet to capture when an event was actually completed.
Future<DateTime?> showMarkCompleteSheet(
  BuildContext context, {
  DateTime? initialDate,
  String? notes,
}) async {
  final l = AppLocalizations.of(context)!;
  var selected = initialDate ?? DateTime.now();
  final notesController = TextEditingController(text: notes ?? '');

  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.markCompleteSheetTitle, style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l.markCompleteSheetSubtitle, style: Theme.of(ctx).textTheme.bodyMedium),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.completedOn),
              subtitle: Text(
                MaterialLocalizations.of(ctx).formatMediumDate(selected),
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: selected,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  selected = calendarDateOnly(picked);
                  (ctx as Element).markNeedsBuild();
                }
              },
            ),
            TextField(
              controller: notesController,
              decoration: InputDecoration(labelText: l.notes),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, selected),
              child: Text(l.markCompletedAction),
            ),
          ],
        ),
      );
    },
  );
}
